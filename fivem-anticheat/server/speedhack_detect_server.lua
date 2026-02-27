-- ============================================================
--  AntiCheat Server: Speedhack Detection Handler  v1.0.0
--
--  Client'tan gelen speedhack tespit raporlarını işler:
--    - Discord webhook loglama
--    - Config.Action'a göre aksiyon (ban/kick/warn)
--    - Admin bypass
--    - Rate limiting
-- ============================================================

local _lastReport = {} -- [playerId] = timestamp

-- -------------------------------------------------------
--  Discord webhook log gönder
-- -------------------------------------------------------
local function SendSpeedLog(playerId, playerName, detail, color)
    if not Config.LogWebhook or Config.LogWebhook == "" then
        print(string.format("^1[AntiCheat:Speedhack] ^7%s (ID:%d): %s",
            playerName, playerId, detail))
        return
    end

    local embed = {
        {
            title = "🏃 Speedhack Tespiti",
            description = detail,
            color = color or 16711680,
            fields = {
                { name = "Oyuncu",    value = playerName,                inline = true },
                { name = "ID",        value = tostring(playerId),        inline = true },
                { name = "Sunucu",    value = Config.ServerName or "?",  inline = true },
            },
            footer = {
                text = "AntiCheat Speedhack v1.0.0 • " .. os.date("%Y-%m-%d %H:%M:%S"),
            },
        }
    }

    PerformHttpRequest(Config.LogWebhook, function() end, "POST", json.encode({
        username = "AntiCheat",
        embeds   = embed,
    }), { ["Content-Type"] = "application/json" })
end

-- -------------------------------------------------------
--  Admin bypass kontrolü
-- -------------------------------------------------------
local function IsAdmin(playerId)
    return IsPlayerAceAllowed(playerId, "anticheat.bypass")
end

-- -------------------------------------------------------
--  Speedhack tespit event handler
-- -------------------------------------------------------
RegisterNetEvent("anticheat:speedhackDetected")
AddEventHandler("anticheat:speedhackDetected", function(detail, speed, avgSpeed, inVehicle)
    local src = source
    local playerName = GetPlayerName(src) or "Bilinmiyor"

    -- Admin bypass
    if IsAdmin(src) then
        print(string.format("^3[AntiCheat:Speedhack] ^7Admin bypass: %s (ID:%d)", playerName, src))
        return
    end

    -- Rate limiting: 15 saniyede bir
    local now = GetGameTimer()
    if _lastReport[src] and (now - _lastReport[src]) < 15000 then
        return
    end
    _lastReport[src] = now

    -- Log gönder
    SendSpeedLog(src, playerName, detail, 16711680)

    -- Aksiyon
    local action = Config.Action or "warn"

    if action == "ban" then
        SendSpeedLog(src, playerName,
            string.format("🔨 **BANNED**: Speedhack\nHız: %.0f m/s (%.0f km/h) | %s",
                speed or 0, (speed or 0) * 3.6, inVehicle and "Araç" or "Yaya"),
            16711680)
        DropPlayer(src, string.format(Config.BanMessage, "Speedhack (hız hilesi) tespit edildi"))

    elseif action == "kick" then
        SendSpeedLog(src, playerName,
            string.format("👢 **KICKED**: Speedhack\nHız: %.0f m/s (%.0f km/h) | %s",
                speed or 0, (speed or 0) * 3.6, inVehicle and "Araç" or "Yaya"),
            16744448)
        DropPlayer(src, "[AntiCheat] Speedhack tespit edildi.")

    else
        SendSpeedLog(src, playerName,
            string.format("⚠️ **UYARI**: Speedhack şüphesi\nHız: %.0f m/s (%.0f km/h) | %s",
                speed or 0, (speed or 0) * 3.6, inVehicle and "Araç" or "Yaya"),
            16776960)
    end
end)

-- -------------------------------------------------------
--  Oyuncu ayrıldığında temizlik
-- -------------------------------------------------------
AddEventHandler("playerDropped", function()
    _lastReport[source] = nil
end)
