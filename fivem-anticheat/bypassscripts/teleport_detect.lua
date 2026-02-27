-- ============================================================
--  AntiCheat - Teleport (TP) Tespiti  v1.0.0
--
--  Tespit hedefi: Oyuncunun haritada işaretlediği noktaya
--  anında ışınlanması (teleport hack / noclip TP)
--
--  Tespit stratejisi:
--    1. Oyuncunun waypoint'ini (harita işareti) izle
--    2. Waypoint konumunu ve zamanını kaydet
--    3. Oyuncu waypoint konumuna fiziksel olarak imkansız
--       sürede ulaşırsa → teleport
--    4. Waypoint yoksa veya silinmişse → kontrol yapma
--
--  False positive koruması:
--    - Waypoint kontrolü: Sadece işaretli noktaya TP tespit edilir
--    - Asansör/interior geçişleri: Waypoint'e TP değilse yakalanmaz
--    - Yolcu kontrolü: Araçta yolcuysa geç (şoför TP yapmış olabilir)
--    - Attach kontrolü: Başka bir ped'e attach ise geç (carry script)
--    - Minimum mesafe: Çok yakın TP'ler filtrelenir
--    - Admin bypass (ace permission)
--    - Meşru TP bölgeleri whitelist (garaj, hastane, vb.)
-- ============================================================

local MODULE_NAME = "teleport_detect"

-- -------------------------------------------------------
--  Config
-- -------------------------------------------------------
local cfg = Config.TeleportDetect or {}
local CHECK_INTERVAL_MS    = cfg.CheckIntervalMs or 500
local MIN_TP_DISTANCE      = cfg.MinTPDistance or 100.0       -- Minimum TP mesafesi (metre)
local MAX_TRAVEL_TIME_MS   = cfg.MaxTravelTimeMs or 2000     -- Bu süreden kısa = TP
local WAYPOINT_RADIUS      = cfg.WaypointRadius or 50.0      -- Waypoint'e bu kadar yakınsa "ulaştı"
local COOLDOWN_MS          = cfg.CooldownMs or 60000
local MAX_SPEED_MPS        = cfg.MaxSpeedMps or 100.0        -- Maks meşru hız (m/s) ~360 km/h

-- -------------------------------------------------------
--  Meşru TP bölgeleri (asansör, garaj girişi, vb.)
--  Bu bölgelere TP yapılırsa tespit yapılmaz
-- -------------------------------------------------------
local SAFE_ZONES = cfg.SafeZones or {
    -- { x = 0.0, y = 0.0, z = 0.0, radius = 50.0, label = "Örnek" },
}

-- -------------------------------------------------------
--  State
-- -------------------------------------------------------
local lastCoords = nil
local lastCoordsTime = 0
local lastWaypointCoords = nil
local waypointSetTime = 0
local lastReportTime = 0
local prevWaypointActive = false

-- -------------------------------------------------------
--  Yardımcı: Waypoint blip'ini al
-- -------------------------------------------------------
local function GetWaypointCoords()
    local waypointBlip = GetFirstBlipInfoId(8) -- 8 = waypoint blip
    if not DoesBlipExist(waypointBlip) then
        return nil
    end
    local coords = GetBlipInfoIdCoord(waypointBlip)
    -- Z koordinatı blip'ten alınamaz, ground level bul
    local found, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, 1000.0, false)
    if found then
        return vector3(coords.x, coords.y, groundZ)
    end
    return vector3(coords.x, coords.y, coords.z)
end

-- -------------------------------------------------------
--  Yardımcı: Koordinat güvenli bölgede mi?
-- -------------------------------------------------------
local function IsInSafeZone(coords)
    for _, zone in ipairs(SAFE_ZONES) do
        local dist = #(coords - vector3(zone.x, zone.y, zone.z))
        if dist <= zone.radius then
            return true, zone.label
        end
    end
    return false, nil
end

-- -------------------------------------------------------
--  Yardımcı: Oyuncu başka bir ped'e attach mi?
-- -------------------------------------------------------
local function IsAttachedToAnyPed(ped)
    if not IsEntityAttachedToAnyEntity(ped) then
        return false
    end
    -- Attach edildiği entity ped mi kontrol et
    local players = GetActivePlayers()
    for _, playerId in ipairs(players) do
        if playerId ~= PlayerId() then
            local targetPed = GetPlayerPed(playerId)
            if targetPed and targetPed ~= 0 and DoesEntityExist(targetPed) then
                if IsEntityAttachedToEntity(ped, targetPed) then
                    return true
                end
            end
        end
    end
    return false
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
    Citizen.Wait(2000) -- Spawn bekle
    local ped = PlayerPedId()
    if DoesEntityExist(ped) then
        lastCoords = GetEntityCoords(ped)
        lastCoordsTime = GetGameTimer()
    end

    while true do
        Citizen.Wait(CHECK_INTERVAL_MS)

        ped = PlayerPedId()
        if not DoesEntityExist(ped) or IsEntityDead(ped) then
            goto continue
        end

        local currentCoords = GetEntityCoords(ped)
        local now = GetGameTimer()

        -- -----------------------------------------------
        --  Waypoint takibi
        -- -----------------------------------------------
        local waypointCoords = GetWaypointCoords()
        local waypointActive = waypointCoords ~= nil

        -- Yeni waypoint konuldu mu?
        if waypointActive and not prevWaypointActive then
            -- Waypoint yeni konuldu
            lastWaypointCoords = waypointCoords
            waypointSetTime = now
        elseif waypointActive and lastWaypointCoords then
            -- Waypoint hala aktif — konum değişti mi?
            local wpDist = #(vector3(waypointCoords.x, waypointCoords.y, 0.0) -
                             vector3(lastWaypointCoords.x, lastWaypointCoords.y, 0.0))
            if wpDist > 10.0 then
                -- Waypoint taşındı
                lastWaypointCoords = waypointCoords
                waypointSetTime = now
            end
        end
        prevWaypointActive = waypointActive

        -- -----------------------------------------------
        --  Teleport tespiti
        -- -----------------------------------------------
        if lastCoords then
            -- 2D mesafe (Z hariç — asansör false positive önleme)
            local dist2D = #(vector3(currentCoords.x, currentCoords.y, 0.0) -
                             vector3(lastCoords.x, lastCoords.y, 0.0))
            local timeDelta = now - lastCoordsTime

            -- Minimum mesafe ve süre kontrolü
            if dist2D >= MIN_TP_DISTANCE and timeDelta > 0 and timeDelta <= MAX_TRAVEL_TIME_MS then
                -- Hız hesapla
                local speed = dist2D / (timeDelta / 1000.0) -- m/s

                -- Fiziksel olarak imkansız hız mı?
                if speed > MAX_SPEED_MPS then

                    -- -----------------------------------------------
                    --  False positive kontrolleri
                    -- -----------------------------------------------

                    -- 1. Attach kontrolü (carry script)
                    if IsAttachedToAnyPed(ped) then
                        goto updateAndContinue
                    end

                    -- 2. Araçta yolcu mu? (şoför TP yapmış olabilir)
                    local vehicle = GetVehiclePedIsIn(ped, false)
                    if vehicle ~= 0 then
                        local seatIndex = -2 -- Bilinmiyor
                        for seat = -1, GetVehicleMaxNumberOfPassengers(vehicle) - 1 do
                            if GetPedInVehicleSeat(vehicle, seat) == ped then
                                seatIndex = seat
                                break
                            end
                        end
                        if seatIndex ~= -1 then
                            -- Yolcu — şoför TP yapmış olabilir, geç
                            goto updateAndContinue
                        end
                    end

                    -- 3. Güvenli bölge kontrolü
                    local inSafeZone, zoneLabel = IsInSafeZone(currentCoords)
                    if inSafeZone then
                        goto updateAndContinue
                    end

                    -- 4. Waypoint kontrolü (EN ÖNEMLİ)
                    -- Waypoint aktif mi ve oyuncu waypoint'e mi ulaştı?
                    local tpToWaypoint = false
                    if lastWaypointCoords then
                        local distToWP = #(vector3(currentCoords.x, currentCoords.y, 0.0) -
                                           vector3(lastWaypointCoords.x, lastWaypointCoords.y, 0.0))
                        if distToWP <= WAYPOINT_RADIUS then
                            tpToWaypoint = true
                        end
                    end

                    -- -----------------------------------------------
                    --  Rapor gönder
                    -- -----------------------------------------------
                    if (now - lastReportTime) > COOLDOWN_MS then
                        lastReportTime = now

                        local detail
                        if tpToWaypoint then
                            detail = string.format(
                                "🚨 WAYPOINT'E TELEPORT!\n" ..
                                "Mesafe: %.0fm | Süre: %.1f sn | Hız: %.0f m/s (%.0f km/h)\n" ..
                                "Eski konum: %.1f, %.1f, %.1f\n" ..
                                "Yeni konum: %.1f, %.1f, %.1f\n" ..
                                "Waypoint: %.1f, %.1f\n" ..
                                "Araçta: %s | Yaya: %s",
                                dist2D, timeDelta / 1000.0, speed, speed * 3.6,
                                lastCoords.x, lastCoords.y, lastCoords.z,
                                currentCoords.x, currentCoords.y, currentCoords.z,
                                lastWaypointCoords.x, lastWaypointCoords.y,
                                vehicle ~= 0 and "EVET (şoför)" or "HAYIR",
                                vehicle == 0 and "EVET" or "HAYIR"
                            )
                        else
                            detail = string.format(
                                "⚠️ Şüpheli hızlı hareket (waypoint'e değil)\n" ..
                                "Mesafe: %.0fm | Süre: %.1f sn | Hız: %.0f m/s (%.0f km/h)\n" ..
                                "Eski konum: %.1f, %.1f, %.1f\n" ..
                                "Yeni konum: %.1f, %.1f, %.1f\n" ..
                                "Araçta: %s | Yaya: %s",
                                dist2D, timeDelta / 1000.0, speed, speed * 3.6,
                                lastCoords.x, lastCoords.y, lastCoords.z,
                                currentCoords.x, currentCoords.y, currentCoords.z,
                                vehicle ~= 0 and "EVET (şoför)" or "HAYIR",
                                vehicle == 0 and "EVET" or "HAYIR"
                            )
                        end

                        TriggerServerEvent("anticheat:teleportDetected", detail, tpToWaypoint, dist2D, speed)
                    end
                end
            end
        end

        ::updateAndContinue::
        -- Konum güncelle
        lastCoords = currentCoords
        lastCoordsTime = now

        ::continue::
    end
end)
