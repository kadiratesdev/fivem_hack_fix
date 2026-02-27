-- ============================================================
--  AntiCheat - Silah Hile Tespiti (Server Side)
--
--  Client tarafı ox_inventory:Search ile envanter kontrolünü
--  doğrudan yapar; bu dosya yalnızca ban/kick/warn aksiyonunu
--  ve Discord log'unu yönetir.
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
local function SendWeaponLog(msg)
    print("[AntiCheat:WeaponCheck] " .. msg)
    if Config.LogWebhook and Config.LogWebhook ~= "" then
        PerformHttpRequest(Config.LogWebhook, function() end, "POST",
            json.encode({
                username = Config.ServerName .. " AntiCheat",
                embeds = {{
                    title       = "🔫 Silah Hile Tespiti",
                    description = msg,
                    color       = 16711680,
                    footer      = { text = os.date("%Y-%m-%d %H:%M:%S") }
                }}
            }),
            { ["Content-Type"] = "application/json" }
        )
    end
end

-- -------------------------------------------------------
-- CLIENT → SERVER: Silah hile tespiti bildirimi
-- Client ox_inventory:Search ile kontrol eder,
-- ihlal varsa bu event tetiklenir.
-- -------------------------------------------------------
RegisterNetEvent("anticheat:weaponCheatDetected")
AddEventHandler("anticheat:weaponCheatDetected", function(weaponName, weaponHash, reason)
    local source = source

    -- Temel doğrulama
    if not weaponName or not reason then return end
    weaponName = string.lower(tostring(weaponName))

    local playerName = GetPlayerName(source) or "Unknown"
    local identifier = GetPlayerIdentifier(source)

    -- IgnoredWeapons sunucu tarafında da çift kontrol
    for _, ignored in ipairs(Config.WeaponCheck.IgnoredWeapons) do
        if string.lower(ignored) == weaponName then
            return
        end
    end

    local logMsg = string.format(
        "Oyuncu: %s (%s) | Envanterde olmayan silah: %s (hash: %s)",
        playerName, identifier, weaponName, tostring(weaponHash)
    )
    SendWeaponLog(logMsg)

    -- Aksiyon uygula
    if Config.Action == "ban" then
        TriggerEvent("anticheat:internalBan", source, reason)
    elseif Config.Action == "kick" then
        SendWeaponLog(string.format("KICK | %s (%s) | %s", playerName, identifier, reason))
        DropPlayer(source, "[AntiCheat] Sunucudan atıldınız. Sebep: " .. reason)
    else
        -- warn: sadece log
        SendWeaponLog(string.format("WARN | %s (%s) | %s", playerName, identifier, reason))
    end
end)
