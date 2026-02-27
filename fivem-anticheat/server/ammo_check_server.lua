-- ============================================================
--  AntiCheat - Sınırsız Mermi Tespiti (Server Side)
--
--  Client tarafı mermi artışını tespit eder ve bu event'i
--  tetikler. Bu dosya ban/kick/warn aksiyonunu ve Discord
--  log'unu yönetir.
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
local function SendAmmoLog(msg)
    print("[AntiCheat:AmmoCheck] " .. msg)
    if Config.LogWebhook and Config.LogWebhook ~= "" then
        PerformHttpRequest(Config.LogWebhook, function() end, "POST",
            json.encode({
                username = Config.ServerName .. " AntiCheat",
                embeds = {{
                    title       = "🔫 Sınırsız Mermi Tespiti",
                    description = msg,
                    color       = 16744448, -- Turuncu
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
-- CLIENT → SERVER: Mermi hile tespiti bildirimi
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
        return -- Çok kısa sürede tekrar geldi, spam olabilir
    end
    lastDetection[source] = now

    local playerName = GetPlayerName(source) or "Unknown"
    local identifier = GetPlayerIdentifier(source)

    local logMsg = string.format(
        "Oyuncu: %s (%s) | %s | Mermi: %d",
        playerName, identifier, reason, ammoCount
    )
    SendAmmoLog(logMsg)

    -- Aksiyon uygula
    if Config.Action == "ban" then
        TriggerEvent("anticheat:internalBan", source, "[infinite_ammo] " .. reason)
    elseif Config.Action == "kick" then
        SendAmmoLog(string.format("KICK | %s (%s) | %s", playerName, identifier, reason))
        DropPlayer(source, "[AntiCheat] Sunucudan atıldınız. Sebep: " .. reason)
    else
        -- warn: sadece log
        SendAmmoLog(string.format("WARN | %s (%s) | %s", playerName, identifier, reason))
    end
end)

-- -------------------------------------------------------
-- Oyuncu ayrıldığında rate limit tablosunu temizle
-- -------------------------------------------------------
AddEventHandler("playerDropped", function()
    local source = source
    lastDetection[source] = nil
end)
