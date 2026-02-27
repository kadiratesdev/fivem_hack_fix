-- ============================================================
--  AntiCheat - Yetkisiz Araç Spawn Tespiti  v1.1.0
--
--  Tespit hedefi: Client-side CreateVehicle ile yetkisiz
--  araç oluşturma (MachoInject, 7XCheat, vb.)
--
--  Tespit stratejisi:
--    1. Oyuncunun yakınında yeni oluşan araçları izle
--    2. Araç oluşturulduğunda sunucuya doğrulama iste
--    3. Sunucu, aracın meşru kaynaklardan gelip gelmediğini kontrol eder
--    4. Kısa sürede çok fazla araç spawn = kesin hile
--    5. Oyuncunun tam koordinatında spawn = şüpheli
--
--  False positive koruması:
--    - Garaj, dealer, admin spawn → sunucu whitelist sistemi
--    - NPC araçları (ped sürücülü) filtrelenir
--    - Araç kiralama/test sürüşü scriptleri whitelist
--    - Admin bypass (ace permission)
--    - Spawn noktası mesafe kontrolü (çok yakın = şüpheli)
-- ============================================================

local MODULE_NAME = "vehicle_spawn_detect"

-- -------------------------------------------------------
--  Config
-- -------------------------------------------------------
local cfg = Config.VehicleSpawnDetect or {}
local CHECK_INTERVAL       = cfg.CheckIntervalMs or 2000
local SPAWN_RADIUS         = cfg.SpawnRadius or 10.0
local MAX_SPAWNS_WINDOW    = cfg.MaxSpawnsInWindow or 3
local SPAWN_WINDOW_MS      = cfg.SpawnWindowMs or 30000
local COOLDOWN_MS          = cfg.CooldownMs or 60000
local NPC_DRIVERS_DISABLED = cfg.NPCDriversDisabled or false  -- NPC sürücüler kapalı mı?

-- -------------------------------------------------------
--  State
-- -------------------------------------------------------
local trackedVehicles = {}   -- [netId] = true (zaten bilinen araçlar)
local recentSpawns = {}      -- { timestamp, model, plate }
local lastReportTime = 0
local lastVehicle = 0        -- Son binilen araç entity

-- -------------------------------------------------------
--  Yardımcı: Model hash'ten okunabilir isim
-- -------------------------------------------------------
local function GetDisplayName(modelHash)
    return GetDisplayNameFromVehicleModel(modelHash) or "UNKNOWN"
end

-- -------------------------------------------------------
--  Yardımcı: Araç NPC tarafından mı sürülüyor?
--  NPC araçları filtrelenir (trafik araçları)
-- -------------------------------------------------------
local function IsNPCVehicle(vehicle)
    if not DoesEntityExist(vehicle) then return true end
    local driver = GetPedInVehicleSeat(vehicle, -1)
    if driver and driver ~= 0 and not IsPedAPlayer(driver) then
        return true -- NPC sürücü var
    end
    return false
end

-- -------------------------------------------------------
--  Yardımcı: Eski spawn kayıtlarını temizle
-- -------------------------------------------------------
local function CleanOldSpawns()
    local now = GetGameTimer()
    local cleaned = {}
    for _, s in ipairs(recentSpawns) do
        if (now - s.timestamp) < SPAWN_WINDOW_MS then
            cleaned[#cleaned + 1] = s
        end
    end
    recentSpawns = cleaned
end

-- -------------------------------------------------------
--  Yardımcı: Araç bilgilerini topla
-- -------------------------------------------------------
local function GetVehicleInfo(vehicle)
    local modelHash = GetEntityModel(vehicle)
    local displayName = GetDisplayName(modelHash)
    local plate = GetVehicleNumberPlateText(vehicle) or "?"
    local coords = GetEntityCoords(vehicle)
    local netId = 0
    if NetworkGetEntityIsNetworked(vehicle) then
        netId = NetworkGetNetworkIdFromEntity(vehicle)
    end
    return {
        entity = vehicle,
        model = modelHash,
        displayName = displayName,
        plate = string.gsub(plate, "%s+", ""), -- Boşlukları temizle
        coords = coords,
        netId = netId,
    }
end

-- -------------------------------------------------------
--  Modül kayıt
-- -------------------------------------------------------
RegisterACModule(MODULE_NAME, function()
    -- 5 saniyelik ana döngüde çağrılır
    -- Asıl tespit aşağıdaki thread'de
end)

-- -------------------------------------------------------
--  Ana tespit döngüsü: Yakındaki yeni araçları izle
-- -------------------------------------------------------
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(CHECK_INTERVAL)

        local ped = PlayerPedId()
        if not DoesEntityExist(ped) or IsEntityDead(ped) then
            goto continue
        end

        local playerCoords = GetEntityCoords(ped)
        local vehicles = GetGamePool('CVehicle')

        for _, vehicle in ipairs(vehicles) do
            if DoesEntityExist(vehicle) then
                -- Network ID ile takip et
                local netId = 0
                if NetworkGetEntityIsNetworked(vehicle) then
                    netId = NetworkGetNetworkIdFromEntity(vehicle)
                end

                local trackKey = netId > 0 and netId or vehicle

                -- Zaten bilinen araç mı?
                if not trackedVehicles[trackKey] then
                    trackedVehicles[trackKey] = true

                    -- NPC aracı mı?
                    if IsNPCVehicle(vehicle) then
                        if NPC_DRIVERS_DISABLED then
                            -- NPC sürücüler kapalı sunucuda NPC sürücülü araç = şüpheli
                            -- Silme işlemi projectile thread'inde yapılır
                        else
                            -- Normal sunucu: NPC trafik araçlarını atla
                            goto nextVehicle
                        end
                    end

                    -- Mesafe kontrolü
                    local vehCoords = GetEntityCoords(vehicle)
                    local dist = #(playerCoords - vehCoords)

                    if dist <= SPAWN_RADIUS then
                        -- Yakında yeni bir araç oluştu!
                        local info = GetVehicleInfo(vehicle)
                        local now = GetGameTimer()

                        -- Spawn kaydı ekle
                        recentSpawns[#recentSpawns + 1] = {
                            timestamp = now,
                            model = info.displayName,
                            plate = info.plate,
                            distance = dist,
                        }

                        -- Sunucuya doğrulama iste
                        TriggerServerEvent("anticheat:vehicleSpawnCheck",
                            info.netId,
                            info.displayName,
                            info.plate,
                            dist
                        )

                        -- Hızlı spawn kontrolü (kısa sürede çok araç)
                        CleanOldSpawns()
                        if #recentSpawns >= MAX_SPAWNS_WINDOW then
                            if (now - lastReportTime) > COOLDOWN_MS then
                                lastReportTime = now

                                -- Spawn listesini detay olarak hazırla
                                local spawnList = {}
                                for _, s in ipairs(recentSpawns) do
                                    spawnList[#spawnList + 1] = string.format(
                                        "%s [%s] (%.1fm)",
                                        s.model, s.plate, s.distance
                                    )
                                end

                                local detail = string.format(
                                    "Hızlı araç spawn! %d araç / %d saniye:\n%s",
                                    #recentSpawns,
                                    SPAWN_WINDOW_MS / 1000,
                                    table.concat(spawnList, "\n")
                                )

                                TriggerServerEvent("anticheat:vehicleSpawnDetected", detail)
                            end
                        end
                    end
                end

                ::nextVehicle::
            end
        end

        -- Bellek temizliği: Artık var olmayan araçları sil
        for key, _ in pairs(trackedVehicles) do
            if type(key) == "number" and key > 0 then
                -- netId bazlı — entity hala var mı kontrol et
                local entity = NetworkGetEntityFromNetworkId(key)
                if not entity or entity == 0 or not DoesEntityExist(entity) then
                    trackedVehicles[key] = nil
                end
            end
        end

        ::continue::
    end
end)

-- -------------------------------------------------------
--  Ek tespit: Oyuncu araca bindiğinde kontrol
--  Cheat genellikle TaskWarpPedIntoVehicle kullanır
--  → araç oluşturulur ve hemen binilir
-- -------------------------------------------------------
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)

        local ped = PlayerPedId()
        if not DoesEntityExist(ped) or IsEntityDead(ped) then
            goto continue
        end

        local currentVehicle = GetVehiclePedIsIn(ped, false)

        if currentVehicle ~= 0 and currentVehicle ~= lastVehicle then
            -- Yeni bir araca bindi
            lastVehicle = currentVehicle

            -- Araç çok yeni mi? (oluşturulalı 5 saniyeden az)
            -- GetEntityAge FiveM'de yok, ama araç bilgisini sunucuya gönderebiliriz
            local info = GetVehicleInfo(currentVehicle)

            -- Sunucuya bildir: "Bu araca bindim, meşru mu?"
            TriggerServerEvent("anticheat:vehicleEntered",
                info.netId,
                info.displayName,
                info.plate
            )
        elseif currentVehicle == 0 then
            lastVehicle = 0
        end

        ::continue::
    end
end)

-- ============================================================
--  Tespit 3: Şoförsüz Hızlı Araç (Vehicle Projectile) v1.1.0
--
--  Cheat: CreateVehicle + SetEntityVelocity ile araçları
--  mermi gibi fırlatma. İmzalar:
--    - Şoförsüz araç (sürücü koltuğu boş)
--    - Yüksek hız (normal trafik hızının çok üstünde)
--    - Havada olma (yere temas etmiyor)
--    - Oyuncunun yakınında spawn
--
--  Aksiyon: Tespit edilen araçlar otomatik silinir + log
-- ============================================================

local PROJECTILE_CHECK_MS    = cfg.ProjectileCheckMs or 500
local PROJECTILE_SPEED_THRESHOLD = cfg.ProjectileSpeedThreshold or 50.0  -- m/s (~180 km/h)
local PROJECTILE_RADIUS      = cfg.ProjectileRadius or 50.0
local PROJECTILE_AUTO_DELETE  = cfg.ProjectileAutoDelete ~= false  -- Varsayılan: true
local projectileReportCooldown = 0

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(PROJECTILE_CHECK_MS)

        local ped = PlayerPedId()
        if not DoesEntityExist(ped) or IsEntityDead(ped) then
            goto continue
        end

        local playerCoords = GetEntityCoords(ped)
        local vehicles = GetGamePool('CVehicle')
        local deletedCount = 0
        local detectedList = {}

        for _, vehicle in ipairs(vehicles) do
            if DoesEntityExist(vehicle) then
                -- Mesafe kontrolü
                local vehCoords = GetEntityCoords(vehicle)
                local dist = #(playerCoords - vehCoords)

                if dist <= PROJECTILE_RADIUS then
                    -- Sürücü kontrolü
                    local driver = GetPedInVehicleSeat(vehicle, -1)
                    local hasDriver = driver and driver ~= 0
                    local hasNPCDriver = hasDriver and not IsPedAPlayer(driver)

                    -- Hız kontrolü
                    local velocity = GetEntityVelocity(vehicle)
                    local speed = #(velocity) -- m/s

                    -- -----------------------------------------------
                    --  Durum 1: Şoförsüz + yüksek hız = araç mermisi
                    -- -----------------------------------------------
                    if not hasDriver and speed > PROJECTILE_SPEED_THRESHOLD then
                        local info = GetVehicleInfo(vehicle)

                        detectedList[#detectedList + 1] = string.format(
                            "%s [%s] hız:%.0f m/s (%.0f km/h) mesafe:%.1fm [ŞOFÖRSÜZ]",
                            info.displayName,
                            info.plate,
                            speed,
                            speed * 3.6,
                            dist
                        )

                        -- Otomatik silme
                        if PROJECTILE_AUTO_DELETE then
                            SetEntityAsMissionEntity(vehicle, false, true)
                            DeleteEntity(vehicle)
                            deletedCount = deletedCount + 1
                        end

                    -- -----------------------------------------------
                    --  Durum 2: NPC sürücüler kapalı sunucuda
                    --  NPC sürücülü araç = sahte NPC, hile imzası
                    --  NPC'yi sil + aracı sil
                    -- -----------------------------------------------
                    elseif NPC_DRIVERS_DISABLED and hasNPCDriver then
                        local info = GetVehicleInfo(vehicle)

                        detectedList[#detectedList + 1] = string.format(
                            "%s [%s] hız:%.0f m/s mesafe:%.1fm [SAHTE NPC SÜRÜCÜ]",
                            info.displayName,
                            info.plate,
                            speed,
                            dist
                        )

                        -- NPC sürücüyü sil
                        if PROJECTILE_AUTO_DELETE then
                            SetEntityAsMissionEntity(driver, false, true)
                            DeletePed(driver)
                            -- Aracı da sil
                            SetEntityAsMissionEntity(vehicle, false, true)
                            DeleteEntity(vehicle)
                            deletedCount = deletedCount + 1
                        end

                    -- -----------------------------------------------
                    --  Durum 3: NPC sürücü + yüksek hız (normal sunucu)
                    --  NPC'ler normalde bu hıza ulaşamaz
                    -- -----------------------------------------------
                    elseif hasNPCDriver and speed > PROJECTILE_SPEED_THRESHOLD then
                        local info = GetVehicleInfo(vehicle)

                        detectedList[#detectedList + 1] = string.format(
                            "%s [%s] hız:%.0f m/s (%.0f km/h) mesafe:%.1fm [NPC HIZLI]",
                            info.displayName,
                            info.plate,
                            speed,
                            speed * 3.6,
                            dist
                        )

                        if PROJECTILE_AUTO_DELETE then
                            SetEntityAsMissionEntity(driver, false, true)
                            DeletePed(driver)
                            SetEntityAsMissionEntity(vehicle, false, true)
                            DeleteEntity(vehicle)
                            deletedCount = deletedCount + 1
                        end
                    end
                end
            end
        end

        -- Tespit varsa sunucuya bildir
        if #detectedList > 0 then
            local now = GetGameTimer()
            if (now - projectileReportCooldown) > 10000 then -- 10sn cooldown
                projectileReportCooldown = now

                local detail = string.format(
                    "🚀 Araç mermisi tespiti! %d şoförsüz hızlı araç%s:\n%s",
                    #detectedList,
                    deletedCount > 0 and string.format(" (%d silindi)", deletedCount) or "",
                    table.concat(detectedList, "\n")
                )

                TriggerServerEvent("anticheat:vehicleSpawnDetected", detail)
            end
        end

        ::continue::
    end
end)
