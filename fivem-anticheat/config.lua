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
    infinite_ammo_check     = true,  -- Sınırsız mermi (infinite ammo) tespiti
    aimbot_detect           = true,  -- Aimbot / Silent Aim tespiti
    player_attach_detect    = true,  -- Görünmez yapışma (ghost attach) tespiti
    vehicle_spawn_detect    = true,  -- Yetkisiz araç spawn tespiti
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

-- ============================================================
--  Sınırsız Mermi Tespiti (infinite_ammo_check modülü) v1.3.0
-- ============================================================
Config.AmmoCheck = {

    -- --------------------------------------------------------
    -- Maksimum mermi eşiği
    -- Bu sayının üzerinde mermi tespit edilirse → kesin hile
    -- Normal oyunda en yüksek mermi kapasitesi ~250 civarıdır
    -- --------------------------------------------------------
    MaxAmmo = 250,

    -- --------------------------------------------------------
    -- Maksimum şarjör kapasitesi
    -- Bir şarjör (reload) en fazla bu kadar mermi artırabilir
    -- Bu değerin üzerinde tek seferlik artış → kesin hile
    -- Oyundaki en büyük şarjör ~50 mermidir
    -- --------------------------------------------------------
    MaxMagazineSize = 50,

    -- --------------------------------------------------------
    -- Şüpheli artış eşiği
    -- Tek seferde bu kadar veya daha fazla mermi artışı
    -- tespit edilirse → strike sayılır
    -- MaxMagazineSize'dan küçük olmalı (reload toleransı)
    -- --------------------------------------------------------
    SuspiciousIncrease = 30,

    -- --------------------------------------------------------
    -- Maksimum strike sayısı
    -- Bu kadar şüpheli artış tespit edilirse → hile onayı
    -- Daha yüksek = daha az false positive, daha geç tespit
    -- --------------------------------------------------------
    MaxStrikes = 3,

    -- --------------------------------------------------------
    -- Strike sıfırlama süresi (milisaniye)
    -- Bu süre içinde yeni strike gelmezse sayaç sıfırlanır
    -- 30000 = 30 saniye
    -- --------------------------------------------------------
    StrikeResetMs = 30000,

    -- --------------------------------------------------------
    -- Sabit mermi (stale ammo) tespit eşiği
    -- Oyuncu ateş ediyor ama mermi düşmüyorsa, bu kadar
    -- kontrol döngüsünden sonra şüpheli sayılır
    -- Kontrol aralığı 5 saniye → 3 = 15 saniye boyunca
    -- ateş edip mermi düşmezse → şüpheli
    -- NOT: Bu durum sadece loglanır, ban atılmaz!
    -- --------------------------------------------------------
    StaleAmmoThreshold = 3,

    -- --------------------------------------------------------
    -- Görmezden gelinecek silahlar
    -- Bu silahlar için mermi kontrolü yapılmaz
    -- Örnek: sınırsız mermili etkinlik silahları
    -- --------------------------------------------------------
    IgnoredWeapons = {
        -- "weapon_paintball",
        -- "weapon_stungun",
    },
}

-- ============================================================
--  Aimbot / Silent Aim Tespiti (aimbot_detect modülü) v1.1.0
-- ============================================================
Config.AimbotDetect = {

    -- --------------------------------------------------------
    -- Yavaş döngü aralığı (milisaniye)
    -- Oyuncunun elinde ateşli silah YOKKEN kullanılır
    -- Kaynak tasarrufu sağlar — silah yoksa sık kontrol gereksiz
    -- 1000ms = saniyede 1 kontrol
    -- --------------------------------------------------------
    IdleLoopMs = 1000,

    -- --------------------------------------------------------
    -- Hızlı döngü aralığı (milisaniye)
    -- Oyuncunun elinde ateşli silah VARKEN ama nişan ALMIYORKEN
    -- 100ms = saniyede 10 kontrol
    -- --------------------------------------------------------
    FastLoopMs = 100,

    -- --------------------------------------------------------
    -- Nişan alma döngüsü
    -- Oyuncu aktif olarak nişan alıyorken → Wait(0)
    -- Her frame kontrol edilir — maksimum hassasiyet
    -- Bu ayar config'den değiştirilemez (sabit Wait(0))
    -- --------------------------------------------------------

    -- --------------------------------------------------------
    -- Headshot oranı eşiği
    -- Bu oranın üzerinde headshot yapan oyuncu → şüpheli
    -- Normal oyuncu: %5-15, iyi oyuncu: %15-25
    -- 0.40 = %40 headshot oranı → çok şüpheli
    -- --------------------------------------------------------
    HeadshotRatioThreshold = 0.40,

    -- --------------------------------------------------------
    -- Minimum ateş sayısı (analiz için)
    -- Bu kadar ateş edilmeden headshot oranı kontrol edilmez
    -- Düşük ateş sayısında oran yanıltıcı olabilir
    -- --------------------------------------------------------
    MinShotsForAnalysis = 15,

    -- --------------------------------------------------------
    -- Snap aiming: Hedef değişim süresi eşiği (milisaniye)
    -- Bu süreden kısa sürede farklı bir hedefe geçiş → snap
    -- 200ms = 0.2 saniye (insanüstü hızda hedef değişimi)
    -- --------------------------------------------------------
    SnapTimeThresholdMs = 200,

    -- --------------------------------------------------------
    -- Snap aiming: Minimum açı eşiği (derece)
    -- Eski hedef ile yeni hedef arası bu açıdan büyükse
    -- ve süre eşiğinden kısaysa → snap aiming
    -- 30° = belirgin yön değişikliği
    -- --------------------------------------------------------
    SnapAngleThreshold = 30,

    -- --------------------------------------------------------
    -- Snap aiming: Kaç kez snap yapılırsa şüpheli?
    -- Tek bir snap normal olabilir (fare hareketi)
    -- Ama tekrarlayan snap'ler → aimbot
    -- --------------------------------------------------------
    SnapCountThreshold = 4,

    -- --------------------------------------------------------
    -- Ateş hızı: Pencere süresi (milisaniye)
    -- Bu süre içindeki ateş sayısı kontrol edilir
    -- 2000ms = 2 saniyelik pencere
    -- --------------------------------------------------------
    FireRateWindowMs = 2000,

    -- --------------------------------------------------------
    -- Ateş hızı: Maksimum ateş sayısı (pencere içinde)
    -- Bu sayının üzerinde ateş → anormal hız
    -- Çoğu silah saniyede 5-8 ateş eder
    -- 2 saniyede 20 ateş = saniyede 10 = şüpheli
    -- --------------------------------------------------------
    FireRateMaxShots = 20,

    -- --------------------------------------------------------
    -- Strike sistemi: Maksimum strike puanı
    -- Bu puana ulaşılırsa sunucuya rapor gönderilir
    -- --------------------------------------------------------
    MaxStrikes = 10,

    -- --------------------------------------------------------
    -- Strike sistemi: Sıfırlama süresi (milisaniye)
    -- Bu süre içinde yeni strike gelmezse sayaç sıfırlanır
    -- 60000 = 60 saniye
    -- --------------------------------------------------------
    StrikeResetMs = 60000,

    -- --------------------------------------------------------
    -- Strike ağırlıkları
    -- Her tespit türü farklı puan verir
    -- Daha kesin tespitler daha yüksek puan alır
    -- --------------------------------------------------------
    StrikeWeights = {
        HighHeadshotRatio = 4,  -- Yüksek headshot oranı (en güvenilir)
        SnapAiming        = 3,  -- Snap aiming tespiti
        RapidFire         = 2,  -- Anormal ateş hızı
    },

    -- --------------------------------------------------------
    -- İstatistik sıfırlama aralığı (milisaniye)
    -- Uzun oturumlarda false positive önlemek için
    -- istatistikler periyodik olarak yarıya indirilir
    -- 300000 = 5 dakika
    -- --------------------------------------------------------
    StatResetIntervalMs = 300000,
}

-- ============================================================
--  Görünmez Yapışma Tespiti (player_attach_detect modülü) v1.0.0
--
--  Cheat: Oyuncu başka bir oyuncuya AttachEntityToEntity ile
--  yapışır, kendini görünmez yapar (SetEntityVisible false)
--  ve çarpışmayı kapatır (SetEntityCollision false).
--  "Ghost attach" / "invisible follow" olarak bilinir.
--
--  False positive koruması:
--    - Taşıma scriptleri (carry/piggyback) whitelist animasyonları
--    - Admin bypass: "anticheat.bypass" ace permission
--    - Araç içindeyken kontrol yapılmaz
--    - Threshold sistemi: tek seferlik tespit yetmez
-- ============================================================
Config.PlayerAttachDetect = {

    -- --------------------------------------------------------
    -- Kontrol aralığı (milisaniye)
    -- Her bu kadar sürede bir oyuncunun durumu kontrol edilir
    -- 1000ms = saniyede 1 kontrol
    -- --------------------------------------------------------
    CheckIntervalMs = 1000,

    -- --------------------------------------------------------
    -- Tespit eşiği
    -- Bu kadar üst üste şüpheli durum tespit edilirse
    -- sunucuya rapor gönderilir
    -- Görünmez + attach = 2 puan/kontrol → 2 kontrolde eşik
    -- Sadece attach (görünür) = 1 puan/kontrol → 3 kontrolde eşik
    -- --------------------------------------------------------
    DetectionThreshold = 3,

    -- --------------------------------------------------------
    -- Rapor bekleme süresi (milisaniye)
    -- Bir rapor gönderildikten sonra bu süre boyunca
    -- yeni rapor gönderilmez (spam önleme)
    -- 60000 = 60 saniye
    -- --------------------------------------------------------
    CooldownMs = 60000,

    -- --------------------------------------------------------
    -- Ek whitelist animasyonları
    -- Sunucunuzdaki özel taşıma scriptleri varsa
    -- buraya ekleyebilirsiniz (client tarafında da var)
    -- Format: { dict = "anim_dict", anim = "anim_name" }
    -- --------------------------------------------------------
    -- ExtraCarryAnims = {
    --     { dict = "custom_carry", anim = "carry_idle" },
    -- },
}

-- ============================================================
--  Yetkisiz Araç Spawn Tespiti (vehicle_spawn_detect modülü) v1.0.0
--
--  Cheat: Client-side CreateVehicle ile yetkisiz araç oluşturma
--  (MachoInject, 7XCheat vb. menülerden araç spawn)
--
--  Tespit yöntemi:
--    1. Oyuncunun yakınında yeni oluşan araçları izle
--    2. Sunucu whitelist sistemi ile doğrula
--    3. Hızlı spawn tespiti (kısa sürede çok araç)
--    4. Network dışı araç tespiti (client-only spawn)
--
--  Whitelist entegrasyonu:
--    Garaj/dealer/admin scriptlerinizde araç spawn ettikten sonra:
--    TriggerEvent("anticheat:authorizeVehicle", source, netId, "garage")
-- ============================================================
Config.VehicleSpawnDetect = {

    -- --------------------------------------------------------
    -- Client kontrol aralığı (milisaniye)
    -- Yakındaki yeni araçlar bu aralıkta taranır
    -- 2000ms = 2 saniyede bir
    -- --------------------------------------------------------
    CheckIntervalMs = 2000,

    -- --------------------------------------------------------
    -- Spawn tespit yarıçapı (metre)
    -- Oyuncunun bu mesafe içinde oluşan araçlar izlenir
    -- 10.0m = yakın çevre (çok uzak araçlar filtrelenir)
    -- --------------------------------------------------------
    SpawnRadius = 10.0,

    -- --------------------------------------------------------
    -- Client tarafı: Hızlı spawn eşiği
    -- Bu kadar araç kısa sürede spawn olursa → rapor
    -- --------------------------------------------------------
    MaxSpawnsInWindow = 3,

    -- --------------------------------------------------------
    -- Client tarafı: Hızlı spawn penceresi (milisaniye)
    -- Bu süre içindeki spawn sayısı kontrol edilir
    -- 30000 = 30 saniye
    -- --------------------------------------------------------
    SpawnWindowMs = 30000,

    -- --------------------------------------------------------
    -- Client tarafı: Rapor bekleme süresi (milisaniye)
    -- Bir rapor gönderildikten sonra bu süre boyunca
    -- yeni rapor gönderilmez
    -- 60000 = 60 saniye
    -- --------------------------------------------------------
    CooldownMs = 60000,

    -- --------------------------------------------------------
    -- Sunucu tarafı: Whitelist kaydı süresi (milisaniye)
    -- Meşru araç spawn kaydı bu süre sonra silinir
    -- 30000 = 30 saniye (spawn sonrası yeterli süre)
    -- --------------------------------------------------------
    AuthExpireMs = 30000,

    -- --------------------------------------------------------
    -- Sunucu tarafı: Hızlı spawn eşiği
    -- Sunucu tarafında bu kadar yetkisiz spawn → aksiyon
    -- Client eşiğinden yüksek (sunucu daha güvenilir)
    -- --------------------------------------------------------
    MaxSpawnsServer = 5,

    -- ============================================================
    --  Araç Mermisi / Şoförsüz Hızlı Araç Tespiti  v1.1.0
    --
    --  Cheat: CreateVehicle + SetEntityVelocity ile araçları
    --  mermi gibi fırlatma (vehicle launcher / vehicle gun)
    -- ============================================================

    -- --------------------------------------------------------
    -- Kontrol aralığı (milisaniye)
    -- Şoförsüz hızlı araçlar bu aralıkta taranır
    -- 500ms = saniyede 2 kontrol (hızlı tepki gerekli)
    -- --------------------------------------------------------
    ProjectileCheckMs = 500,

    -- --------------------------------------------------------
    -- Hız eşiği (metre/saniye)
    -- Şoförsüz araç bu hızın üzerindeyse → araç mermisi
    -- 50 m/s = 180 km/h (şoförsüz araç bu hıza ulaşamaz)
    -- Normal trafik: ~15-30 m/s, park halinde: 0
    -- --------------------------------------------------------
    ProjectileSpeedThreshold = 50.0,

    -- --------------------------------------------------------
    -- Tarama yarıçapı (metre)
    -- Bu mesafe içindeki şoförsüz araçlar kontrol edilir
    -- 50m = geniş alan (fırlatılan araçlar hızla uzaklaşır)
    -- --------------------------------------------------------
    ProjectileRadius = 50.0,

    -- --------------------------------------------------------
    -- Otomatik silme
    -- true = tespit edilen araç mermileri otomatik silinir
    -- false = sadece log, silme yapılmaz
    -- ÖNERİ: true (araç mermileri oyuncuları öldürebilir)
    -- --------------------------------------------------------
    ProjectileAutoDelete = true,
}
