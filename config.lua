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
    vehicle_mod_detect      = true,  -- Yetkisiz araç tuning tespiti
    teleport_detect         = true,  -- Teleport (TP) + Freecam tespiti
    speedhack_detect        = true,  -- Speedhack (hız hilesi) tespiti
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

    -- --------------------------------------------------------
    -- NPC sürücüler kapalı mı?
    -- Bazı sunucularda NPC trafik araçları tamamen kapalıdır.
    -- Bu durumda NPC sürücülü bir araç görmek = hile imzası
    -- true  = NPC sürücüler kapalı → NPC sürücülü araç = şüpheli → sil
    -- false = NPC sürücüler açık → NPC trafik araçları normal (filtrele)
    -- --------------------------------------------------------
    NPCDriversDisabled = false,

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

-- ============================================================
--  Yetkisiz Araç Tuning Tespiti (vehicle_mod_detect modülü) v1.0.0
--
--  Cheat: Client-side SetVehicleMod ile tüm modları max'a
--  çıkarma (max tuning, cam filmi, patlak lastik koruması)
--
--  Tespit yöntemi (Before/After):
--    1. Araca binildiğinde tüm mod değerleri kaydedilir (snapshot)
--    2. Periyodik olarak mevcut modlar kontrol edilir
--    3. Eşik aşılırsa sunucuya bildirilir
--    4. Sunucu: meslek + admin kontrolü
--    5. Yetkisiz ise → araç sil + ban/kick
--
--  Framework desteği: ESX, QBCore, Standalone
-- ============================================================
Config.VehicleModDetect = {

    -- --------------------------------------------------------
    -- Kontrol aralığı (milisaniye)
    -- Araçtaki mod değişiklikleri bu aralıkta kontrol edilir
    -- 3000ms = 3 saniyede bir (çok sık olursa performans etkiler)
    -- --------------------------------------------------------
    CheckIntervalMs = 3000,

    -- --------------------------------------------------------
    -- Mod değişiklik eşiği
    -- Tek seferde bu kadar veya daha fazla mod değişirse → şüpheli
    -- Max tuning cheat'i 50 mod'u aynı anda değiştirir
    -- Normal mekanik: 1-2 mod aynı anda
    -- 5 = güvenli eşik (false positive düşük)
    -- --------------------------------------------------------
    ModChangeThreshold = 5,

    -- --------------------------------------------------------
    -- Rapor bekleme süresi (milisaniye)
    -- 60000 = 60 saniye
    -- --------------------------------------------------------
    CooldownMs = 60000,

    -- --------------------------------------------------------
    -- İzin verilen meslekler
    -- Bu mesleklerdeki oyuncular araç tuning yapabilir
    -- ESX/QBCore job.name değerleri kullanılır
    -- --------------------------------------------------------
    AllowedJobs = {
        "mechanic",     -- Mekanik
        "tuner",        -- Tuning uzmanı
        "bennys",       -- Benny's çalışanı
        -- "police",    -- Polis (araç modifikasyonu gerekiyorsa)
        -- "cardealer",  -- Araç satıcısı
    },

    -- --------------------------------------------------------
    -- Framework zorunlu mu?
    -- true  = ESX/QBCore bulunamazsa → meslek kontrolü başarısız → aksiyon al
    -- false = Framework yoksa meslek kontrolü atlanır (sadece admin kontrolü)
    -- Standalone sunucular için false yapın
    -- --------------------------------------------------------
    RequireFramework = false,
}

-- ============================================================
--  Teleport (TP) Tespiti (teleport_detect modülü) v1.0.0
--
--  Cheat: Oyuncunun haritada işaretlediği noktaya anında
--  ışınlanması (SetEntityCoords ile teleport)
--
--  Tespit yöntemi:
--    1. Waypoint (harita işareti) konumunu izle
--    2. Oyuncunun konumunu periyodik kaydet
--    3. Fiziksel olarak imkansız hızda hareket → TP
--    4. Waypoint'e TP = kesin hile
--    5. Waypoint'e olmayan hızlı hareket = sadece log (asansör olabilir)
--
--  False positive koruması:
--    - Waypoint kontrolü (en önemli!)
--    - Yolcu kontrolü (şoför TP yapmış olabilir)
--    - Attach kontrolü (carry script)
--    - Güvenli bölgeler (asansör, garaj, hastane)
--    - 2D mesafe (Z hariç — asansör false positive önleme)
--    - Admin bypass
-- ============================================================
Config.TeleportDetect = {

    -- --------------------------------------------------------
    -- Kontrol aralığı (milisaniye)
    -- Oyuncunun konumu bu aralıkta kaydedilir
    -- 500ms = saniyede 2 kontrol
    -- Daha düşük = daha hassas ama daha fazla kaynak
    -- --------------------------------------------------------
    CheckIntervalMs = 500,

    -- --------------------------------------------------------
    -- Minimum TP mesafesi (metre)
    -- Bu mesafeden kısa TP'ler filtrelenir
    -- 100m = kısa mesafe TP'ler (asansör, interior) yakalanmaz
    -- --------------------------------------------------------
    MinTPDistance = 100.0,

    -- --------------------------------------------------------
    -- Maksimum seyahat süresi (milisaniye)
    -- Bu süreden kısa sürede MinTPDistance'dan fazla mesafe
    -- kat edilirse → teleport
    -- 2000ms = 2 saniye
    -- --------------------------------------------------------
    MaxTravelTimeMs = 2000,

    -- --------------------------------------------------------
    -- Waypoint yakınlık yarıçapı (metre)
    -- Oyuncu waypoint'e bu kadar yakınsa "ulaştı" sayılır
    -- 50m = GPS hassasiyeti (waypoint tam noktaya düşmeyebilir)
    -- --------------------------------------------------------
    WaypointRadius = 50.0,

    -- --------------------------------------------------------
    -- Rapor bekleme süresi (milisaniye)
    -- 60000 = 60 saniye
    -- --------------------------------------------------------
    CooldownMs = 60000,

    -- --------------------------------------------------------
    -- Maksimum meşru hız (metre/saniye)
    -- Bu hızın üzerinde hareket → fiziksel olarak imkansız
    -- 100 m/s = 360 km/h (en hızlı araç bile bu hıza zor ulaşır)
    -- Daha düşük = daha hassas ama daha fazla false positive
    -- --------------------------------------------------------
    MaxSpeedMps = 100.0,

    -- --------------------------------------------------------
    -- Güvenli bölgeler
    -- Bu bölgelere TP yapılırsa tespit yapılmaz
    -- Asansör çıkışları, garaj spawn noktaları, hastane vb.
    -- Format: { x, y, z, radius, label }
    -- --------------------------------------------------------
    SafeZones = {
        -- { x = 0.0, y = 0.0, z = 0.0, radius = 50.0, label = "Örnek Asansör" },
        -- { x = 340.0, y = -580.0, z = 74.0, radius = 30.0, label = "Pillbox Hastane" },
        -- { x = -1105.0, y = -843.0, z = 37.0, radius = 50.0, label = "Garaj" },
    },

    -- ============================================================
    --  Freecam Tespiti  v1.1.0
    --
    --  Cheat: CreateCamWithParams + RenderScriptCams ile kamerayı
    --  ped'den ayırıp serbest hareket ettirme (uzaktan gözetleme)
    --
    --  Tespit: Kamera ile ped arasındaki mesafe > eşik
    --  Normal gameplay'de kamera ped'den max 10-15m uzaklaşır
    -- ============================================================

    -- --------------------------------------------------------
    -- Freecam kontrol aralığı (milisaniye)
    -- 1000ms = saniyede 1 kontrol
    -- --------------------------------------------------------
    FreecamCheckMs = 1000,

    -- --------------------------------------------------------
    -- Maksimum kamera-ped mesafesi (metre)
    -- Bu mesafenin üzerinde kamera = freecam
    -- Normal gameplay: max 10-15m (araç kamerası)
    -- 50m = güvenli eşik (false positive düşük)
    -- --------------------------------------------------------
    FreecamMaxDistance = 50.0,

    -- --------------------------------------------------------
    -- Grace period (milisaniye)
    -- İlk tespitten sonra bu süre beklenir
    -- Kısa süreli scripted cam'ler (cutscene, telefon) için tolerans
    -- 5000ms = 5 saniye (cutscene genellikle daha kısa)
    -- --------------------------------------------------------
    FreecamGraceMs = 5000,
}

-- ============================================================
--  Speedhack Tespiti (speedhack_detect modülü) v1.0.0
--
--  Cheat: SetRunSprintMultiplierForPlayer ve SetPedMoveRateOverride
--  ile oyuncunun hareket hızını artırma (3x, 10x fast run)
--
--  Tespit yöntemi:
--    1. Oyuncunun gerçek hızını mesafe/süre ile ölç
--    2. Yaya/araç hız limitini aşıyorsa → strike
--    3. Tekrarlayan ihlaller → ban
--
--  Normal hızlar: Yürüme ~1.5 m/s | Koşma ~5.5 | Sprint ~7.5
--  Cheat hızları: 3x = ~22 m/s | 10x = ~75 m/s
-- ============================================================
Config.SpeedhackDetect = {

    -- --------------------------------------------------------
    -- Kontrol aralığı (milisaniye)
    -- Hız ölçümü bu aralıkta yapılır
    -- 1000ms = saniyede 1 ölçüm
    -- --------------------------------------------------------
    CheckIntervalMs = 1000,

    -- --------------------------------------------------------
    -- Yaya maksimum hız (metre/saniye)
    -- Bu hızın üzerinde yaya hareketi → şüpheli
    -- Normal sprint: ~7.5 m/s
    -- 15 m/s = 2x sprint hızı (güvenli eşik)
    -- --------------------------------------------------------
    MaxFootSpeed = 15.0,

    -- --------------------------------------------------------
    -- Araç maksimum hız (metre/saniye)
    -- Bu hızın üzerinde araç hareketi → şüpheli
    -- En hızlı süper araç: ~80 m/s (~288 km/h)
    -- 100 m/s = 360 km/h (güvenli eşik)
    -- --------------------------------------------------------
    MaxVehicleSpeed = 100.0,

    -- --------------------------------------------------------
    -- Strike sistemi: Maksimum strike
    -- Bu kadar üst üste hız ihlali → ban
    -- 5 = 5 saniye boyunca sürekli hız ihlali
    -- --------------------------------------------------------
    MaxStrikes = 5,

    -- --------------------------------------------------------
    -- Strike azalma süresi (milisaniye)
    -- Bu sürede 1 strike düşer
    -- 30000 = 30 saniye
    -- --------------------------------------------------------
    StrikeDecayMs = 30000,

    -- --------------------------------------------------------
    -- Rapor bekleme süresi (milisaniye)
    -- 60000 = 60 saniye
    -- --------------------------------------------------------
    CooldownMs = 60000,
}
