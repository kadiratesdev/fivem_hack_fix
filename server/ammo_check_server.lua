-- ============================================================
--  AntiCheat - Sınırsız Mermi Tespiti (Server Side)  v1.3.0
--
--  İki farklı event dinler:
--    1. anticheat:ammoCheatDetected → Kesin hile, aksiyon uygula
--    2. anticheat:ammoSuspicious    → Şüpheli durum, SADECE logla
--
--  Her iki durumda da silah client tarafında elinden alınır.
-- ============================================================

-- -------------------------------------------------------
-- Yardımcı: Oyuncunun identifier'ını al
-- -------------------------------------------------------
local function GetPlayerIdentifier(source)
    local ids = { "license", "steam", "discord", "ip" }
    for _, idType in ipairs(ids) do
        local id = GetPlayerIdentifierByType(source, idType)
        if id then return id end
    end
    return tostring(source)
end

-- -------------------------------------------------------
-- Yardımcı: Discord webhook log
-- -------------------------------------------------------
local function SendAmmoLog(title, msg, color)
    print("[AntiCheat:AmmoCheck] " .. msg)
    if Config.LogWebhook and Config.LogWebhook ~= "" then
        PerformHttpRequest(Config.LogWebhook, function() end, "POST",
            json.encode({
                username = Config.ServerName .. " AntiCheat",
                embeds = {{
                    title       = title,
                    description = msg,
                    color       = color or 16744448, -- Turuncu varsayılan
                    footer      = { text = os.date("%Y-%m-%d %H:%M:%S") }
                }}
            }),
            { ["Content-Type"] = "application/json" }
        )
    end
end

-- -------------------------------------------------------
-- Rate limiting: Aynı oyuncudan spam event'leri engelle
-- -------------------------------------------------------
local lastDetection = {} -- { [source] = timestamp }
local COOLDOWN_MS = 10000 -- 10 saniye cooldown

-- -------------------------------------------------------
-- EVENT 1: Kesin hile tespiti → Aksiyon uygula
-- (Şarjör limiti aşımı, tekrarlayan artış, max mermi aşımı)
-- -------------------------------------------------------
RegisterNetEvent("anticheat:ammoCheatDetected")
AddEventHandler("anticheat:ammoCheatDetected", function(weaponName, ammoCount, reason)
    local source = source

    -- Temel doğrulama
    if not weaponName or not reason then return end
    weaponName = string.lower(tostring(weaponName))
    ammoCount = tonumber(ammoCount) or 0

    -- Rate limiting kontrolü
    local now = GetGameTimer()
    if lastDetection[source] and (now - lastDetection[source]) < COOLDOWN_MS then
        return
    end
    lastDetection[source] = now

    local playerName = GetPlayerName(source) or "Unknown"
    local identifier = GetPlayerIdentifier(source)

    local logMsg = string.format(
        "**Oyuncu:** %s (%s)\n**Sebep:** %s\n**Mermi:** %d\n**Aksiyon:** Silah elinden alındı",
        playerName, identifier, reason, ammoCount
    )
    SendAmmoLog("🔫 Mermi Hilesi Tespiti", logMsg, 16711680) -- Kırmızı

    -- Aksiyon uygula (config'e göre)
    if Config.Action == "ban" then
        TriggerEvent("anticheat:internalBan", source, "[infinite_ammo] " .. reason)
    elseif Config.Action == "kick" then
        SendAmmoLog("⚠️ KICK", string.format("%s (%s) | %s", playerName, identifier, reason), 16744448)
        DropPlayer(source, "[AntiCheat] Sunucudan atıldınız. Sebep: " .. reason)
    else
        -- warn: sadece log (silah zaten client tarafında alındı)
        SendAmmoLog("⚠️ WARN", string.format("%s (%s) | %s", playerName, identifier, reason), 16776960)
    end
end)

-- -------------------------------------------------------
-- EVENT 2: Şüpheli durum → SADECE logla, ban/kick YOK
-- (Sabit mermi tespiti: ateş ediyor ama mermi düşmüyor)
-- Silah client tarafında zaten elinden alındı
-- -------------------------------------------------------
RegisterNetEvent("anticheat:ammoSuspicious")
AddEventHandler("anticheat:ammoSuspicious", function(weaponName, ammoCount, reason)
    local source = source

    -- Temel doğrulama
    if not weaponName or not reason then return end
    weaponName = string.lower(tostring(weaponName))
    ammoCount = tonumber(ammoCount) or 0

    -- Rate limiting kontrolü
    local now = GetGameTimer()
    if lastDetection[source] and (now - lastDetection[source]) < COOLDOWN_MS then
        return
    end
    lastDetection[source] = now

    local playerName = GetPlayerName(source) or "Unknown"
    local identifier = GetPlayerIdentifier(source)

    local logMsg = string.format(
        "**Oyuncu:** %s (%s)\n**Sebep:** %s\n**Mermi:** %d\n**Aksiyon:** Silah elinden alındı (sadece log, ban yok)",
        playerName, identifier, reason, ammoCount
    )
    -- Sarı renk: şüpheli ama kesin değil
    SendAmmoLog("🟡 Şüpheli Mermi Aktivitesi", logMsg, 16776960) -- Sarı

    -- BAN/KICK YOK - Sadece loglama
    -- Silah zaten client tarafında elinden alındı
    print(string.format("[AntiCheat:AmmoCheck] SUSPICIOUS (no ban) | %s (%s) | %s",
        playerName, identifier, reason))
end)

-- -------------------------------------------------------
-- Oyuncu ayrıldığında rate limit tablosunu temizle
-- -------------------------------------------------------
AddEventHandler("playerDropped", function()
    local source = source
    lastDetection[source] = nil
end)
