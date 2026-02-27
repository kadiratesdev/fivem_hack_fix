-- ============================================================
--  AntiCheat Server: Aimbot Detection Handler  v1.0.0
--
--  Client'tan gelen aimbot tespit raporlarını işler:
--    - Discord webhook ile loglama
--    - Config.Action'a göre aksiyon (ban/kick/warn)
--    - Rate limiting (spam önleme)
-- ============================================================

local _lastReport = {} -- [playerId] = timestamp (rate limiting)

-- -------------------------------------------------------
--  Discord webhook log gönder
-- -------------------------------------------------------
local function SendAimbotLog(playerId, playerName, detail, color)
    if not Config.LogWebhook or Config.LogWebhook == "" then
        -- Webhook yoksa sadece konsola yaz
        print(string.format("^1[AntiCheat:Aimbot] ^7%s (ID:%d): %s",
            playerName, playerId, detail))
        return
    end

    local embed = {
        {
            title = "🎯 Aimbot Tespiti",
            description = detail,
            color = color or 16711680, -- Kırmızı
            fields = {
                { name = "Oyuncu",    value = playerName,                inline = true },
                { name = "ID",        value = tostring(playerId),        inline = true },
                { name = "Sunucu",    value = Config.ServerName or "?",  inline = true },
            },
            footer = {
                text = "AntiCheat Aimbot Detection v1.0.0 • " .. os.date("%Y-%m-%d %H:%M:%S"),
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
--  Aimbot tespit event handler
-- -------------------------------------------------------
RegisterNetEvent("anticheat:aimbotDetected")
AddEventHandler("anticheat:aimbotDetected", function(detail)
    local src = source
    local playerName = GetPlayerName(src) or "Bilinmiyor"

    -- Rate limiting: 15 saniyede bir rapor
    local now = GetGameTimer()
    if _lastReport[src] and (now - _lastReport[src]) < 15000 then
        return
    end
    _lastReport[src] = now

    -- Log gönder (kırmızı embed)
    SendAimbotLog(src, playerName, detail, 16711680)

    -- Config.Action'a göre aksiyon
    local action = Config.Action or "warn"

    if action == "ban" then
        -- Ban
        local reason = "Aimbot / Silent Aim kullanımı tespit edildi"
        SendAimbotLog(src, playerName,
            string.format("🔨 **BANNED**: %s\nDetay: %s", reason, detail),
            16711680)

        DropPlayer(src, string.format(Config.BanMessage, reason))

    elseif action == "kick" then
        -- Kick
        local reason = "Aimbot / Silent Aim şüphesi"
        SendAimbotLog(src, playerName,
            string.format("👢 **KICKED**: %s\nDetay: %s", reason, detail),
            16744448) -- Turuncu

        DropPlayer(src, string.format(Config.BanMessage, reason))

    else
        -- Warn (sadece log)
        SendAimbotLog(src, playerName,
            string.format("⚠️ **UYARI**: Aimbot şüphesi\nDetay: %s", detail),
            16776960) -- Sarı
    end
end)

-- -------------------------------------------------------
--  Oyuncu ayrıldığında rate limit temizle
-- -------------------------------------------------------
AddEventHandler("playerDropped", function()
    _lastReport[source] = nil
end)
