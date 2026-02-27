-- ============================================================
--  AntiCheat Server: Player Attach Detection Handler  v1.0.0
--
--  Client'tan gelen yapışma (attach) tespit raporlarını işler:
--    - Discord webhook ile loglama (renk kodlu)
--    - Config.Action'a göre aksiyon (ban/kick/warn)
--    - Rate limiting (spam önleme)
--    - Admin bypass (ace permission)
-- ============================================================

local _lastReport = {} -- [playerId] = timestamp (rate limiting)

-- -------------------------------------------------------
--  Discord webhook log gönder
-- -------------------------------------------------------
local function SendAttachLog(playerId, playerName, detail, color)
    if not Config.LogWebhook or Config.LogWebhook == "" then
        print(string.format("^1[AntiCheat:PlayerAttach] ^7%s (ID:%d): %s",
            playerName, playerId, detail))
        return
    end

    local embed = {
        {
            title = "👻 Görünmez Yapışma Tespiti",
            description = detail,
            color = color or 16711680, -- Kırmızı
            fields = {
                { name = "Oyuncu",    value = playerName,                inline = true },
                { name = "ID",        value = tostring(playerId),        inline = true },
                { name = "Sunucu",    value = Config.ServerName or "?",  inline = true },
            },
            footer = {
                text = "AntiCheat PlayerAttach v1.0.0 • " .. os.date("%Y-%m-%d %H:%M:%S"),
            },
        }
    }

    PerformHttpRequest(Config.LogWebhook, function(err, text, headers)
        -- Callback (hata olursa sessizce geç)
    end, "POST", json.encode({
        username  = "AntiCheat",
        embeds    = embed,
    }), { ["Content-Type"] = "application/json" })
end

-- -------------------------------------------------------
--  Admin bypass kontrolü
--  "anticheat.bypass" ace permission'ı olan oyuncular
--  tespit edilmez (admin noclip, test amaçlı vb.)
-- -------------------------------------------------------
local function IsAdmin(playerId)
    return IsPlayerAceAllowed(playerId, "anticheat.bypass")
end

-- -------------------------------------------------------
--  Player attach tespit event handler
-- -------------------------------------------------------
RegisterNetEvent("anticheat:playerAttachDetected")
AddEventHandler("anticheat:playerAttachDetected", function(detail, targetServerId)
    local src = source
    local playerName = GetPlayerName(src) or "Bilinmiyor"

    -- Admin bypass
    if IsAdmin(src) then
        print(string.format("^3[AntiCheat:PlayerAttach] ^7Admin bypass: %s (ID:%d)", playerName, src))
        return
    end

    -- Rate limiting: 15 saniyede bir rapor
    local now = GetGameTimer()
    if _lastReport[src] and (now - _lastReport[src]) < 15000 then
        return
    end
    _lastReport[src] = now

    -- Hedef oyuncu bilgisi
    local targetName = "?"
    if targetServerId then
        targetName = GetPlayerName(targetServerId) or "?"
    end

    local fullDetail = string.format(
        "%s\n**Hedef Oyuncu**: %s (ID: %s)",
        detail,
        targetName,
        tostring(targetServerId or "?")
    )

    -- Log gönder (kırmızı embed)
    SendAttachLog(src, playerName, fullDetail, 16711680)

    -- Config.Action'a göre aksiyon
    local action = Config.Action or "warn"

    if action == "ban" then
        local reason = "Görünmez yapışma (ghost attach) hilesi tespit edildi"
        SendAttachLog(src, playerName,
            string.format("🔨 **BANNED**: %s\nDetay: %s", reason, fullDetail),
            16711680) -- Kırmızı

        DropPlayer(src, string.format(Config.BanMessage, reason))

    elseif action == "kick" then
        local reason = "Görünmez yapışma şüphesi"
        SendAttachLog(src, playerName,
            string.format("👢 **KICKED**: %s\nDetay: %s", reason, fullDetail),
            16744448) -- Turuncu

        DropPlayer(src, string.format(Config.BanMessage, reason))

    else
        -- Warn (sadece log)
        SendAttachLog(src, playerName,
            string.format("⚠️ **UYARI**: Yapışma şüphesi\nDetay: %s", fullDetail),
            16776960) -- Sarı
    end
end)

-- -------------------------------------------------------
--  Oyuncu ayrıldığında rate limit temizle
-- -------------------------------------------------------
AddEventHandler("playerDropped", function()
    _lastReport[source] = nil
end)
