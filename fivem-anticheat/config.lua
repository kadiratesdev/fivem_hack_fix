-- ============================================================
--  AntiCheat Config
-- ============================================================

Config = {}

-- Ban mesajı
Config.BanMessage = "^1[AntiCheat] ^7Sunucudan banlandınız.\nSebep: %s"

-- Ban süresi (dakika, 0 = kalıcı)
Config.BanDuration = 0

-- Log kanalı (Discord webhook veya print)
Config.LogWebhook = "" -- Discord webhook URL buraya

-- Tespit edilen bypass scriptleri için aksiyon
-- "ban"  = direkt ban
-- "kick" = kick + log
-- "warn" = sadece log
Config.Action = "ban"

-- Hangi bypass modülleri aktif?
Config.Modules = {
    entity_grab             = true,  -- 7XCheat / MachoInject entity grab tespiti
    weapon_inventory_check  = true,  -- ox_inventory silah envanter kontrolü
    -- yeni modüller buraya eklenebilir
    -- mymod = true,
}

-- Sunucu adı (log mesajlarında görünür)
Config.ServerName = "MyFiveM Server"

-- ============================================================
--  Silah Envanter Kontrolü (weapon_inventory_check modülü)
-- ============================================================
Config.WeaponCheck = {

    -- --------------------------------------------------------
    -- Görmezden gelinecek silahlar
    -- Paintball etkinliği, özel event silahları vb.
    -- ox_inventory item adını (küçük harf) buraya yazın
    -- --------------------------------------------------------
    IgnoredWeapons = {
        "weapon_paintball",       -- Paintball etkinliği
        -- "weapon_snowball",     -- Kar topu etkinliği
        -- "weapon_flare",        -- Fişek etkinliği
        -- Buraya istediğiniz kadar ekleyebilirsiniz
    },

    -- --------------------------------------------------------
    -- Görmezden gelinecek bölgeler (koordinat + yarıçap)
    -- Bu bölgelerde silah kontrolü çalışmaz
    -- Örnek: paintball arenası, etkinlik alanı vb.
    -- --------------------------------------------------------
    IgnoredZones = {
        -- { x = 0.0, y = 0.0, z = 0.0, radius = 50.0, label = "Örnek Bölge" },
        -- { x = 1234.5, y = -567.8, z = 30.0, radius = 100.0, label = "Paintball Arenası" },
    },

    -- --------------------------------------------------------
    -- Silah adı → hash eşleştirme tablosu
    -- ox_inventory item adı (büyük harf) ile GTA hash eşleşmesi
    -- Yeni silah eklemek için buraya satır ekleyin
    -- --------------------------------------------------------
    WeaponHashMap = {
        -- Tabancalar
        ["WEAPON_PISTOL"]               = true,
        ["WEAPON_PISTOL_MK2"]           = true,
        ["WEAPON_COMBATPISTOL"]         = true,
        ["WEAPON_APPISTOL"]             = true,
        ["WEAPON_STUNGUN"]              = true,
        ["WEAPON_FLAREGUN"]             = true,
        ["WEAPON_MARKSMANPISTOL"]       = true,
        ["WEAPON_REVOLVER"]             = true,
        ["WEAPON_REVOLVER_MK2"]         = true,
        ["WEAPON_DOUBLEACTION"]         = true,
        ["WEAPON_SNSPISTOL"]            = true,
        ["WEAPON_SNSPISTOL_MK2"]        = true,
        ["WEAPON_HEAVYPISTOL"]          = true,
        ["WEAPON_VINTAGEPISTOL"]        = true,
        ["WEAPON_CERAMICPISTOL"]        = true,
        ["WEAPON_NAVYREVOLVER"]         = true,
        ["WEAPON_GADGETPISTOL"]         = true,
        -- SMG
        ["WEAPON_MICROSMG"]             = true,
        ["WEAPON_SMG"]                  = true,
        ["WEAPON_SMG_MK2"]              = true,
        ["WEAPON_ASSAULTSMG"]           = true,
        ["WEAPON_COMBATPDW"]            = true,
        ["WEAPON_MACHINEPISTOL"]        = true,
        ["WEAPON_MINISMG"]              = true,
        ["WEAPON_RAYCARBINE"]           = true,
        -- Tüfekler
        ["WEAPON_ASSAULTRIFLE"]         = true,
        ["WEAPON_ASSAULTRIFLE_MK2"]     = true,
        ["WEAPON_CARBINERIFLE"]         = true,
        ["WEAPON_CARBINERIFLE_MK2"]     = true,
        ["WEAPON_ADVANCEDRIFLE"]        = true,
        ["WEAPON_SPECIALCARBINE"]       = true,
        ["WEAPON_SPECIALCARBINE_MK2"]   = true,
        ["WEAPON_BULLPUPRIFLE"]         = true,
        ["WEAPON_BULLPUPRIFLE_MK2"]     = true,
        ["WEAPON_COMPACTRIFLE"]         = true,
        ["WEAPON_MILITARYRIFLE"]        = true,
        ["WEAPON_HEAVYRIFLE"]           = true,
        ["WEAPON_TACTICALRIFLE"]        = true,
        -- Keskin nişancı
        ["WEAPON_SNIPERRIFLE"]          = true,
        ["WEAPON_HEAVYSNIPER"]          = true,
        ["WEAPON_HEAVYSNIPER_MK2"]      = true,
        ["WEAPON_MARKSMANRIFLE"]        = true,
        ["WEAPON_MARKSMANRIFLE_MK2"]    = true,
        ["WEAPON_PRECISIONRIFLE"]       = true,
        -- Pompalı
        ["WEAPON_PUMPSHOTGUN"]          = true,
        ["WEAPON_PUMPSHOTGUN_MK2"]      = true,
        ["WEAPON_SAWNOFFSHOTGUN"]       = true,
        ["WEAPON_ASSAULTSHOTGUN"]       = true,
        ["WEAPON_BULLPUPSHOTGUN"]       = true,
        ["WEAPON_MUSKET"]               = true,
        ["WEAPON_HEAVYSHOTGUN"]         = true,
        ["WEAPON_DBSHOTGUN"]            = true,
        ["WEAPON_AUTOSHOTGUN"]          = true,
        ["WEAPON_COMBATSHOTGUN"]        = true,
        -- Ağır silahlar
        ["WEAPON_MINIGUN"]              = true,
        ["WEAPON_FIREWORK"]             = true,
        ["WEAPON_RAILGUN"]              = true,
        ["WEAPON_HOMINGLAUNCHER"]       = true,
        ["WEAPON_PROXMINE"]             = true,
        ["WEAPON_SNOWLAUNCHER"]         = true,
        ["WEAPON_RAILGUNXM3"]           = true,
        -- RPG / Patlayıcı
        ["WEAPON_RPG"]                  = true,
        ["WEAPON_GRENADELAUNCHER"]      = true,
        ["WEAPON_GRENADELAUNCHER_SMOKE"]= true,
        ["WEAPON_EMPLAUNCHER"]          = true,
        -- Atılan silahlar
        ["WEAPON_GRENADE"]              = true,
        ["WEAPON_BZGAS"]                = true,
        ["WEAPON_SMOKEGRENADE"]         = true,
        ["WEAPON_FLARE"]                = true,
        ["WEAPON_MOLOTOV"]              = true,
        ["WEAPON_STICKYBOMB"]           = true,
        ["WEAPON_PROXMINE"]             = true,
        ["WEAPON_SNOWBALL"]             = true,
        ["WEAPON_PIPEBOMB"]             = true,
        ["WEAPON_BALL"]                 = true,
        ["WEAPON_COMPACTLAUNCHER"]      = true,
        ["WEAPON_RAYMINIGUN"]           = true,
        -- Yakın dövüş
        ["WEAPON_DAGGER"]               = true,
        ["WEAPON_BAT"]                  = true,
        ["WEAPON_BOTTLE"]               = true,
        ["WEAPON_CROWBAR"]              = true,
        ["WEAPON_FLASHLIGHT"]           = true,
        ["WEAPON_GOLFCLUB"]             = true,
        ["WEAPON_HAMMER"]               = true,
        ["WEAPON_HATCHET"]              = true,
        ["WEAPON_KNUCKLE"]              = true,
        ["WEAPON_KNIFE"]                = true,
        ["WEAPON_MACHETE"]              = true,
        ["WEAPON_SWITCHBLADE"]          = true,
        ["WEAPON_NIGHTSTICK"]           = true,
        ["WEAPON_WRENCH"]               = true,
        ["WEAPON_BATTLEAXE"]            = true,
        ["WEAPON_POOLCUE"]              = true,
        ["WEAPON_STONE_HATCHET"]        = true,
        -- Özel / Etkinlik (IgnoredWeapons ile birlikte kullanın)
        ["WEAPON_PAINTBALL"]            = true,
    },
}
