-- ============================================================
--  AntiCheat Server: Teleport Detection Handler  v1.0.0
--
--  Client'tan gelen teleport tespit raporlarını işler:
--    - Waypoint'e TP = kesin hile → ban/kick
--    - Waypoint'e olmayan hızlı hareket = şüpheli → log
--    - Discord webhook loglama
--    - Admin bypass
--    - Rate limiting
-- ============================================================

local _lastReport = {} -- [playerId] = timestamp

-- -------------------------------------------------------
--  Discord webhook log gönder
-- -------------------------------------------------------
local function SendTPLog(playerId, playerName, detail, color)
    if not Config.LogWebhook or Config.LogWebhook == "" then
        print(string.format("^1[AntiCheat:Teleport] ^7%s (ID:%d): %s",
            playerName, playerId, detail))
        return
    end

    local embed = {
        {
            title = "⚡ Teleport Tespiti",
            description = detail,
            color = color or 16711680,
            fields = {
                { name = "Oyuncu",    value = playerName,                inline = true },
                { name = "ID",        value = tostring(playerId),        inline = true },
                { name = "Sunucu",    value = Config.ServerName or "?",  inline = true },
            },
            footer = {
                text = "AntiCheat Teleport v1.0.0 • " .. os.date("%Y-%m-%d %H:%M:%S"),
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
--  Teleport tespit event handler
-- -------------------------------------------------------
RegisterNetEvent("anticheat:teleportDetected")
AddEventHandler("anticheat:teleportDetected", function(detail, tpToWaypoint, distance, speed)
    local src = source
    local playerName = GetPlayerName(src) or "Bilinmiyor"

    -- Admin bypass
    if IsAdmin(src) then
        print(string.format("^3[AntiCheat:Teleport] ^7Admin bypass: %s (ID:%d)", playerName, src))
        return
    end

    -- Rate limiting: 15 saniyede bir
    local now = GetGameTimer()
    if _lastReport[src] and (now - _lastReport[src]) < 15000 then
        return
    end
    _lastReport[src] = now

    if tpToWaypoint then
        -- -----------------------------------------------
        --  Waypoint'e TP = kesin hile
        -- -----------------------------------------------
        SendTPLog(src, playerName, detail, 16711680) -- Kırmızı

        local action = Config.Action or "warn"

        if action == "ban" then
            SendTPLog(src, playerName,
                string.format("🔨 **BANNED**: Waypoint'e teleport\nMesafe: %.0fm | Hız: %.0f m/s",
                    distance or 0, speed or 0),
                16711680)
            DropPlayer(src, string.format(Config.BanMessage, "Teleport (waypoint'e ışınlanma) tespit edildi"))

        elseif action == "kick" then
            SendTPLog(src, playerName,
                string.format("👢 **KICKED**: Waypoint'e teleport\nMesafe: %.0fm | Hız: %.0f m/s",
                    distance or 0, speed or 0),
                16744448) -- Turuncu
            DropPlayer(src, "[AntiCheat] Teleport tespit edildi.")

        else
            SendTPLog(src, playerName,
                string.format("⚠️ **UYARI**: Waypoint'e teleport\nMesafe: %.0fm | Hız: %.0f m/s",
                    distance or 0, speed or 0),
                16776960) -- Sarı
        end
    else
        -- -----------------------------------------------
        --  Waypoint'e olmayan hızlı hareket = sadece log
        --  (asansör, interior geçişi olabilir)
        -- -----------------------------------------------
        SendTPLog(src, playerName, detail, 16776960) -- Sarı (uyarı)
    end
end)

-- -------------------------------------------------------
--  Oyuncu ayrıldığında temizlik
-- -------------------------------------------------------
AddEventHandler("playerDropped", function()
    _lastReport[source] = nil
end)
