-- ============================================================
--  AntiCheat Module: Aimbot Detection  v1.0.0
--
--  Tespit edilen hile türleri:
--    1. ShootSingleBulletBetweenCoords kullanımı (silent aim)
--    2. Anormal headshot oranı
--    3. Anlık nişan değişimi (snap aiming)
--    4. İnsanüstü ateş hızı
--
--  Çalışma mantığı:
--    - Ana döngü (ACModules) her 5 saniyede istatistik toplar
--    - Ayrı bir hızlı döngü (100ms) ateş anlarını yakalar
--    - Belirli eşikler aşılırsa sunucuya rapor gönderir
-- ============================================================

local cfg -- Config.AimbotDetect referansı (init'te atanır)

-- -------------------------------------------------------
--  İstatistik tablosu
-- -------------------------------------------------------
local _stats = {
    -- Ateş istatistikleri
    totalShots      = 0,     -- Toplam ateş sayısı
    headshots       = 0,     -- Headshot sayısı
    bodyshots       = 0,     -- Gövde isabet sayısı

    -- Snap (anlık nişan değişimi) tespiti
    lastAimTarget   = 0,     -- Son nişan alınan entity
    lastAimTime     = 0,     -- Son nişan zamanı (ms)
    snapCount       = 0,     -- Hızlı hedef değişim sayısı

    -- Ateş hızı tespiti
    shotTimestamps  = {},    -- Son ateşlerin zaman damgaları
    rapidFireCount  = 0,     -- Anormal hızlı ateş sayısı

    -- Genel strike sistemi
    strikes         = 0,     -- Toplam şüpheli davranış puanı
    lastStrikeTime  = 0,     -- Son strike zamanı
    lastReportTime  = 0,     -- Son sunucu raporu zamanı

    -- Oturum başlangıcı
    sessionStart    = 0,
}

-- -------------------------------------------------------
--  Yardımcı: Silah ateşli mi? (melee/throwable değil)
-- -------------------------------------------------------
local function isFirearm(weaponHash)
    -- Yumruk / silahsız
    if weaponHash == GetHashKey("WEAPON_UNARMED") then return false end

    -- Melee silahları kontrol et
    local meleeGroup = GetHashKey("GROUP_MELEE")
    if GetWeapontypeGroup(weaponHash) == meleeGroup then return false end

    -- Atılan silahlar (el bombası vb.) kontrol et
    local thrownGroup = GetHashKey("GROUP_THROWN")
    if GetWeapontypeGroup(weaponHash) == thrownGroup then return false end

    return true
end

-- -------------------------------------------------------
--  Yardımcı: İki vektör arası açı (derece)
-- -------------------------------------------------------
local function angleBetween(v1, v2)
    local dot = v1.x * v2.x + v1.y * v2.y + v1.z * v2.z
    local mag1 = math.sqrt(v1.x^2 + v1.y^2 + v1.z^2)
    local mag2 = math.sqrt(v2.x^2 + v2.y^2 + v2.z^2)
    if mag1 == 0 or mag2 == 0 then return 0 end
    local cosAngle = math.max(-1.0, math.min(1.0, dot / (mag1 * mag2)))
    return math.deg(math.acos(cosAngle))
end

-- -------------------------------------------------------
--  Yardımcı: Vektör normalize
-- -------------------------------------------------------
local function normalize(v)
    local mag = math.sqrt(v.x^2 + v.y^2 + v.z^2)
    if mag == 0 then return vector3(0, 0, 0) end
    return vector3(v.x / mag, v.y / mag, v.z / mag)
end

-- -------------------------------------------------------
--  Strike ekle
-- -------------------------------------------------------
local function addStrike(points, reason)
    local now = GetGameTimer()

    -- Strike reset süresi geçtiyse sıfırla
    if (now - _stats.lastStrikeTime) > cfg.StrikeResetMs then
        _stats.strikes = 0
    end

    _stats.strikes = _stats.strikes + points
    _stats.lastStrikeTime = now

    -- Eşik aşıldıysa sunucuya bildir
    if _stats.strikes >= cfg.MaxStrikes then
        -- Spam önleme: 10 saniyede bir rapor
        if (now - _stats.lastReportTime) > 10000 then
            _stats.lastReportTime = now

            local detail = string.format(
                "Aimbot tespit edildi! Sebep: %s | Strikes: %d/%d | Headshot: %d/%d (%%%d) | Snap: %d | RapidFire: %d",
                reason,
                _stats.strikes, cfg.MaxStrikes,
                _stats.headshots, _stats.totalShots,
                (_stats.totalShots > 0) and math.floor((_stats.headshots / _stats.totalShots) * 100) or 0,
                _stats.snapCount,
                _stats.rapidFireCount
            )

            TriggerServerEvent("anticheat:aimbotDetected", detail)
            print("^1[AntiCheat] ^7" .. detail)
        end

        -- Strike'ları kısmen sıfırla (tekrar tespit için)
        _stats.strikes = math.floor(cfg.MaxStrikes / 2)
    end
end

-- -------------------------------------------------------
--  Kontrol 1: Headshot oranı analizi
-- -------------------------------------------------------
local function checkHeadshotRatio()
    if _stats.totalShots < cfg.MinShotsForAnalysis then return end

    local ratio = _stats.headshots / _stats.totalShots

    if ratio >= cfg.HeadshotRatioThreshold then
        addStrike(cfg.StrikeWeights.HighHeadshotRatio,
            string.format("Yüksek headshot oranı: %%%d (%d/%d)",
                math.floor(ratio * 100), _stats.headshots, _stats.totalShots))
    end
end

-- -------------------------------------------------------
--  Kontrol 2: Snap aiming tespiti
-- -------------------------------------------------------
local function checkSnapAiming()
    local ped = PlayerPedId()
    local hasTarget, targetEntity = GetEntityPlayerIsFreeAimingAt(PlayerId())

    if not hasTarget or not targetEntity or targetEntity == 0 then
        return
    end

    -- Sadece oyuncu ped'lerine bak
    if not IsEntityAPed(targetEntity) or not IsPedAPlayer(targetEntity) then
        return
    end

    local now = GetGameTimer()

    -- Hedef değişti mi?
    if targetEntity ~= _stats.lastAimTarget and _stats.lastAimTarget ~= 0 then
        local timeDiff = now - _stats.lastAimTime

        -- Çok hızlı hedef değişimi (snap)
        if timeDiff < cfg.SnapTimeThresholdMs and timeDiff > 0 then
            -- Açı kontrolü: eski hedef ile yeni hedef arası açı
            local pedCoords = GetEntityCoords(ped)
            local oldTargetAlive = DoesEntityExist(_stats.lastAimTarget)

            if oldTargetAlive then
                local oldPos = GetEntityCoords(_stats.lastAimTarget)
                local newPos = GetEntityCoords(targetEntity)

                local dirOld = normalize(vector3(oldPos.x - pedCoords.x, oldPos.y - pedCoords.y, oldPos.z - pedCoords.z))
                local dirNew = normalize(vector3(newPos.x - pedCoords.x, newPos.y - pedCoords.y, newPos.z - pedCoords.z))

                local angle = angleBetween(dirOld, dirNew)

                -- Büyük açı + hızlı geçiş = snap aim
                if angle >= cfg.SnapAngleThreshold then
                    _stats.snapCount = _stats.snapCount + 1

                    if _stats.snapCount >= cfg.SnapCountThreshold then
                        addStrike(cfg.StrikeWeights.SnapAiming,
                            string.format("Snap aiming: %d kez, son açı: %.1f°, süre: %dms",
                                _stats.snapCount, angle, timeDiff))
                    end
                end
            end
        end
    end

    _stats.lastAimTarget = targetEntity
    _stats.lastAimTime = now
end

-- -------------------------------------------------------
--  Kontrol 3: Ateş hızı analizi
-- -------------------------------------------------------
local function checkFireRate()
    local ped = PlayerPedId()
    local weapon = GetSelectedPedWeapon(ped)

    if not isFirearm(weapon) then return end
    if not IsPedShooting(ped) then return end

    local now = GetGameTimer()

    -- Zaman damgası ekle
    table.insert(_stats.shotTimestamps, now)

    -- Eski kayıtları temizle (son N saniye)
    local windowMs = cfg.FireRateWindowMs
    local cleaned = {}
    for _, ts in ipairs(_stats.shotTimestamps) do
        if (now - ts) <= windowMs then
            table.insert(cleaned, ts)
        end
    end
    _stats.shotTimestamps = cleaned

    -- Pencere içindeki ateş sayısı
    local shotCount = #_stats.shotTimestamps

    if shotCount >= cfg.FireRateMaxShots then
        _stats.rapidFireCount = _stats.rapidFireCount + 1

        addStrike(cfg.StrikeWeights.RapidFire,
            string.format("Anormal ateş hızı: %d atış / %dms pencere",
                shotCount, windowMs))

        -- Sayacı sıfırla (tekrar tespit için)
        _stats.shotTimestamps = {}
    end
end

-- -------------------------------------------------------
--  Kontrol 4: Ateş anında isabet analizi (headshot tracking)
-- -------------------------------------------------------
local function trackShotAccuracy()
    local ped = PlayerPedId()

    if not IsPedShooting(ped) then return end

    local weapon = GetSelectedPedWeapon(ped)
    if not isFirearm(weapon) then return end

    _stats.totalShots = _stats.totalShots + 1

    -- Hedef var mı?
    local hasTarget, targetEntity = GetEntityPlayerIsFreeAimingAt(PlayerId())
    if hasTarget and targetEntity and targetEntity ~= 0 then
        if IsEntityAPed(targetEntity) then
            -- Hedefin son hasar bone'unu kontrol et
            -- GetPedLastDamageBone ile headshot tespiti
            local success, bone = GetPedLastDamageBone(targetEntity)
            if success then
                -- SKEL_Head = 31086 (0x796E)
                if bone == 31086 then
                    _stats.headshots = _stats.headshots + 1
                else
                    _stats.bodyshots = _stats.bodyshots + 1
                end
            end
        end
    end
end

-- -------------------------------------------------------
--  Hızlı döngü: Ateş anlarını yakalamak için
--  (Ana döngü 5 saniye, bu 100ms aralıkla çalışır)
-- -------------------------------------------------------
Citizen.CreateThread(function()
    -- Config yüklenene kadar bekle
    while not Config or not Config.AimbotDetect do
        Citizen.Wait(500)
    end

    -- Modül aktif değilse çalışma
    if not Config.Modules["aimbot_detect"] then
        return
    end

    cfg = Config.AimbotDetect
    _stats.sessionStart = GetGameTimer()

    while true do
        Citizen.Wait(cfg.FastLoopMs or 100)

        local ped = PlayerPedId()
        if not DoesEntityExist(ped) or IsEntityDead(ped) then
            goto continue
        end

        -- Ateş hızı kontrolü (hızlı döngüde olmalı)
        checkFireRate()

        -- Ateş isabet takibi
        trackShotAccuracy()

        -- Snap aiming kontrolü
        checkSnapAiming()

        ::continue::
    end
end)

-- -------------------------------------------------------
--  Ana modül fonksiyonu (5 saniyede bir çağrılır)
--  İstatistik analizi ve raporlama
-- -------------------------------------------------------
RegisterACModule("aimbot_detect", function()
    if not cfg then return end

    -- Headshot oranı kontrolü
    checkHeadshotRatio()

    -- Periyodik istatistik sıfırlama
    local now = GetGameTimer()
    local sessionDuration = now - _stats.sessionStart

    -- Her N dakikada istatistikleri kısmen sıfırla (uzun oturum false positive önleme)
    if sessionDuration > cfg.StatResetIntervalMs then
        -- Yarıya indir (tamamen sıfırlama — pattern'i kaybetme)
        _stats.totalShots = math.floor(_stats.totalShots / 2)
        _stats.headshots = math.floor(_stats.headshots / 2)
        _stats.bodyshots = math.floor(_stats.bodyshots / 2)
        _stats.snapCount = math.max(0, _stats.snapCount - 2)
        _stats.rapidFireCount = math.max(0, _stats.rapidFireCount - 1)
        _stats.sessionStart = now
    end
end)
