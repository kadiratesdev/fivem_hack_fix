-- ============================================================
--  AntiCheat - Speedhack Tespiti  v1.0.0
--
--  Tespit hedefi: SetRunSprintMultiplierForPlayer ve
--  SetPedMoveRateOverride ile hız artırma (speedhack)
--
--  Tespit stratejisi:
--    1. Oyuncunun gerçek hareket hızını mesafe/süre ile ölç
--    2. Yaya hız limitini aşıyorsa → şüpheli
--    3. Araç hız limitini aşıyorsa → şüpheli
--    4. Strike sistemi: Tekrarlayan ihlaller → ban
--
--  Normal hızlar (m/s):
--    Yürüme: ~1.5 | Koşma: ~5.5 | Sprint: ~7.5
--    Araç (süper): ~80 | Araç (normal): ~50
--
--  Cheat hızları:
--    3x fast run: ~22 m/s | 10x fast run: ~75 m/s
--
--  False positive koruması:
--    - Araç içindeyken farklı eşik (araçlar hızlı)
--    - Düşme/fırlatılma toleransı (ragdoll kontrolü)
--    - Attach kontrolü (carry script)
--    - Strike sistemi (tek seferlik spike yetmez)
--    - Admin bypass
-- ============================================================

local MODULE_NAME = "speedhack_detect"

-- -------------------------------------------------------
--  Config
-- -------------------------------------------------------
local cfg = Config.SpeedhackDetect or {}
local CHECK_INTERVAL_MS     = cfg.CheckIntervalMs or 1000
local MAX_FOOT_SPEED        = cfg.MaxFootSpeed or 15.0       -- m/s (yaya max)
local MAX_VEHICLE_SPEED     = cfg.MaxVehicleSpeed or 100.0   -- m/s (araç max ~360 km/h)
local MAX_STRIKES           = cfg.MaxStrikes or 5
local STRIKE_DECAY_MS       = cfg.StrikeDecayMs or 30000     -- 30sn'de 1 strike düşür
local COOLDOWN_MS           = cfg.CooldownMs or 60000

-- -------------------------------------------------------
--  State
-- -------------------------------------------------------
local lastPos = nil
local lastPosTime = 0
local strikes = 0
local lastStrikeDecay = 0
local lastReportTime = 0
local speedSamples = {}       -- Son N hız ölçümü (ortalama için)
local MAX_SAMPLES = 5

-- -------------------------------------------------------
--  Yardımcı: Hız örneği ekle ve ortalama hesapla
-- -------------------------------------------------------
local function AddSpeedSample(speed)
    speedSamples[#speedSamples + 1] = speed
    if #speedSamples > MAX_SAMPLES then
        table.remove(speedSamples, 1)
    end
end

local function GetAverageSpeed()
    if #speedSamples == 0 then return 0 end
    local sum = 0
    for _, s in ipairs(speedSamples) do
        sum = sum + s
    end
    return sum / #speedSamples
end

-- -------------------------------------------------------
--  Yardımcı: Oyuncu ragdoll durumunda mı?
--  Ragdoll'da hız yüksek olabilir (düşme, fırlatılma)
-- -------------------------------------------------------
local function IsInRagdoll(ped)
    return IsPedRagdoll(ped) or IsPedFalling(ped)
end

-- -------------------------------------------------------
--  Yardımcı: Oyuncu başka bir entity'ye attach mi?
-- -------------------------------------------------------
local function IsAttached(ped)
    return IsEntityAttachedToAnyEntity(ped)
end

-- -------------------------------------------------------
--  Modül kayıt
-- -------------------------------------------------------
RegisterACModule(MODULE_NAME, function()
    -- 5 saniyelik ana döngüde çağrılır
end)

-- -------------------------------------------------------
--  Ana tespit döngüsü
-- -------------------------------------------------------
Citizen.CreateThread(function()
    -- İlk konum kaydı
    Citizen.Wait(3000) -- Spawn bekle
    local ped = PlayerPedId()
    if DoesEntityExist(ped) then
        lastPos = GetEntityCoords(ped)
        lastPosTime = GetGameTimer()
    end

    while true do
        Citizen.Wait(CHECK_INTERVAL_MS)

        ped = PlayerPedId()
        if not DoesEntityExist(ped) or IsEntityDead(ped) then
            lastPos = nil
            speedSamples = {}
            goto continue
        end

        local currentPos = GetEntityCoords(ped)
        local now = GetGameTimer()

        -- Strike decay
        if (now - lastStrikeDecay) > STRIKE_DECAY_MS and strikes > 0 then
            strikes = strikes - 1
            lastStrikeDecay = now
        end

        if lastPos then
            local timeDelta = (now - lastPosTime) / 1000.0 -- saniye
            if timeDelta > 0 then
                -- 2D mesafe (Z hariç — düşme/tırmanma false positive)
                local dist2D = #(vector3(currentPos.x, currentPos.y, 0.0) -
                                 vector3(lastPos.x, lastPos.y, 0.0))
                local speed = dist2D / timeDelta -- m/s

                AddSpeedSample(speed)

                -- -----------------------------------------------
                --  False positive kontrolleri
                -- -----------------------------------------------

                -- Ragdoll (düşme/fırlatılma)
                if IsInRagdoll(ped) then
                    goto updatePos
                end

                -- Attach (carry script, araç çekici vb.)
                if IsAttached(ped) then
                    goto updatePos
                end

                -- -----------------------------------------------
                --  Hız kontrolü
                -- -----------------------------------------------
                local inVehicle = IsPedInAnyVehicle(ped, false)
                local maxSpeed = inVehicle and MAX_VEHICLE_SPEED or MAX_FOOT_SPEED
                local avgSpeed = GetAverageSpeed()

                -- Anlık hız VE ortalama hız eşiği aşıyorsa
                if speed > maxSpeed and avgSpeed > (maxSpeed * 0.8) then
                    strikes = strikes + 1
                    lastStrikeDecay = now

                    local detail = string.format(
                        "Hız ihlali! Anlık: %.1f m/s (%.0f km/h) | Ort: %.1f m/s | Eşik: %.0f m/s\n" ..
                        "Yaya: %s | Araç: %s | Strike: %d/%d",
                        speed, speed * 3.6, avgSpeed, maxSpeed,
                        not inVehicle and "EVET" or "HAYIR",
                        inVehicle and "EVET" or "HAYIR",
                        strikes, MAX_STRIKES
                    )

                    print(string.format("^1[AntiCheat:Speedhack] ^7%s", detail))

                    -- Strike eşiği aşıldı mı?
                    if strikes >= MAX_STRIKES then
                        if (now - lastReportTime) > COOLDOWN_MS then
                            lastReportTime = now
                            strikes = 0
                            speedSamples = {}

                            local reportDetail = string.format(
                                "🏃 SPEEDHACK TESPİTİ!\n" ..
                                "Son hız: %.1f m/s (%.0f km/h)\n" ..
                                "Ortalama hız: %.1f m/s\n" ..
                                "Eşik: %.0f m/s (%s)\n" ..
                                "Konum: %.1f, %.1f, %.1f",
                                speed, speed * 3.6,
                                avgSpeed,
                                maxSpeed,
                                inVehicle and "araç" or "yaya",
                                currentPos.x, currentPos.y, currentPos.z
                            )

                            TriggerServerEvent("anticheat:speedhackDetected", reportDetail, speed, avgSpeed, inVehicle)
                        end
                    end
                end
            end
        end

        ::updatePos::
        lastPos = currentPos
        lastPosTime = now

        ::continue::
    end
end)
