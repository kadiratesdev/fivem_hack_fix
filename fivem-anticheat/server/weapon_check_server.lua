-- ============================================================
--  AntiCheat - Silah Envanter Kontrolü (Server Side)
--  ox_inventory ile entegre çalışır.
--
--  Client'tan gelen "anticheat:checkWeaponInventory" eventini
--  dinler, ox_inventory'den envanter sorgular, silah yoksa
--  silahı alır ve ban uygular.
-- ============================================================

-- -------------------------------------------------------
-- Yardımcı: ox_inventory'den oyuncunun silahlarını al
-- -------------------------------------------------------
local function GetPlayerWeaponsFromInventory(source)
    -- ox_inventory exports kullanılır
    local inventory = exports.ox_inventory:GetInventoryItems(source)
    if not inventory then return {} end

    local weapons = {}
    for _, item in ipairs(inventory) do
        if item and item.name then
            weapons[string.lower(item.name)] = true
        end
    end
    return weapons
end

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
-- Yardımcı: Oyuncunun elindeki silahı zorla al
-- -------------------------------------------------------
local function RemoveWeaponFromPlayer(source, weaponHash)
    -- Client'a silahı kaldırma komutu gönder
    TriggerClientEvent("anticheat:forceRemoveWeapon", source, weaponHash)
end

-- -------------------------------------------------------
-- Yardımcı: Ban uygula
-- -------------------------------------------------------
local function BanPlayerWeapon(source, reason)
    local identifier = GetPlayerIdentifier(source)
    local name       = GetPlayerName(source) or "Unknown"
    local expiry     = Config.BanDuration == 0 and 0 or (os.time() + Config.BanDuration * 60)

    -- bannedPlayers global tablosuna ekle (server.lua'daki ile aynı tablo)
    -- Eğer ayrı dosyada çalışıyorsa TriggerEvent ile server.lua'ya ilet
    TriggerEvent("anticheat:internalBan", source, reason)

    local msg = string.format(
        "BAN | Silah Hile | Oyuncu: %s (%s) | Sebep: %s",
        name, identifier, reason
    )
    SendWeaponLog(msg)
end

-- -------------------------------------------------------
-- CLIENT → SERVER: Silah envanter kontrolü
-- -------------------------------------------------------
RegisterNetEvent("anticheat:checkWeaponInventory")
AddEventHandler("anticheat:checkWeaponInventory", function(weaponName, weaponHash)
    local source = source

    -- Temel doğrulama
    if not weaponName or not weaponHash then return end
    weaponName = string.lower(tostring(weaponName))

    -- ox_inventory'den envanter al
    local playerWeapons = GetPlayerWeaponsFromInventory(source)

    -- Envanterde bu silah var mı?
    if playerWeapons[weaponName] then
        -- Silah envanterde mevcut, sorun yok
        return
    end

    -- IgnoredWeapons kontrolü (server tarafında da çift kontrol)
    for _, ignored in ipairs(Config.WeaponCheck.IgnoredWeapons) do
        if string.lower(ignored) == weaponName then
            return
        end
    end

    -- Silah envanterde YOK ama elde var → hile!
    local playerName = GetPlayerName(source) or "Unknown"
    local identifier = GetPlayerIdentifier(source)

    local logMsg = string.format(
        "Oyuncu: %s (%s) | Envanterde olmayan silah tespit edildi: %s (hash: %s)",
        playerName, identifier, weaponName, tostring(weaponHash)
    )
    SendWeaponLog(logMsg)

    -- Önce silahı zorla al
    RemoveWeaponFromPlayer(source, weaponHash)

    -- Aksiyon uygula
    local reason = string.format("Envanterde olmayan silah: %s", weaponName)

    if Config.Action == "ban" then
        BanPlayerWeapon(source, reason)
    elseif Config.Action == "kick" then
        local name = GetPlayerName(source) or "Unknown"
        local id   = GetPlayerIdentifier(source)
        SendWeaponLog(string.format("KICK | %s (%s) | %s", name, id, reason))
        DropPlayer(source, "[AntiCheat] Sunucudan atıldınız. Sebep: " .. reason)
    else
        -- warn: sadece log
        local name = GetPlayerName(source) or "Unknown"
        local id   = GetPlayerIdentifier(source)
        SendWeaponLog(string.format("WARN | %s (%s) | %s", name, id, reason))
    end
end)

