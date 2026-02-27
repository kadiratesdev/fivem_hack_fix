-- ============================================================
--  AntiCheat - Yetkisiz Araç Tuning Tespiti  v1.0.0
--
--  Tespit hedefi: Client-side SetVehicleMod ile yetkisiz
--  araç modifikasyonu (max tuning, window tint, vb.)
--
--  Tespit stratejisi (Before/After):
--    1. Araca binildiğinde tüm mod değerlerini kaydet (snapshot)
--    2. Periyodik olarak mevcut modları kontrol et
--    3. Değişiklik tespit edilirse → sunucuya bildir
--    4. Sunucu: meslek + admin kontrolü
--    5. Yetkisiz ise → araç sil + ban/kick
--
--  False positive koruması:
--    - Mekanik/tuning meslekleri whitelist (sunucu tarafı)
--    - Admin bypass (ace permission)
--    - Tek mod değişikliği toleransı (threshold sistemi)
--    - Araç değiştirme anında snapshot yenilenir
-- ============================================================

local MODULE_NAME = "vehicle_mod_detect"

-- -------------------------------------------------------
--  Config
-- -------------------------------------------------------
local cfg = Config.VehicleModDetect or {}
local CHECK_INTERVAL_MS    = cfg.CheckIntervalMs or 3000
local MOD_CHANGE_THRESHOLD = cfg.ModChangeThreshold or 5    -- Kaç mod aynı anda değişirse şüpheli?
local COOLDOWN_MS          = cfg.CooldownMs or 60000

-- -------------------------------------------------------
--  State
-- -------------------------------------------------------
local currentVehicle = 0
local modSnapshot = {}          -- { [modType] = modIndex }
local windowTintSnapshot = -1
local tyresBurstSnapshot = true
local lastReportTime = 0

-- -------------------------------------------------------
--  Yardımcı: Araçtaki tüm modları snapshot olarak al
-- -------------------------------------------------------
local function TakeModSnapshot(vehicle)
    local snapshot = {}
    SetVehicleModKit(vehicle, 0) -- Mod kit'i aktifleştir (okuma için gerekli)
    for modType = 0, 49 do
        snapshot[modType] = GetVehicleMod(vehicle, modType)
    end
    return snapshot
end

-- -------------------------------------------------------
--  Yardımcı: İki snapshot arasındaki farkları bul
-- -------------------------------------------------------
local function CompareSnapshots(before, after)
    local changes = {}
    for modType = 0, 49 do
        local oldVal = before[modType] or -1
        local newVal = after[modType] or -1
        if oldVal ~= newVal then
            changes[#changes + 1] = {
                modType = modType,
                oldVal  = oldVal,
                newVal  = newVal,
                maxVal  = -1, -- Sonra doldurulacak
            }
        end
    end
    return changes
end

-- -------------------------------------------------------
--  Yardımcı: Mod değişikliklerini detaylı string yap
-- -------------------------------------------------------
local function FormatChanges(changes, vehicle)
    local lines = {}
    for _, c in ipairs(changes) do
        local maxMod = GetNumVehicleMods(vehicle, c.modType) - 1
        lines[#lines + 1] = string.format(
            "Mod[%d]: %d → %d (max: %d)",
            c.modType, c.oldVal, c.newVal, maxMod
        )
    end
    return table.concat(lines, "\n")
end

-- -------------------------------------------------------
--  Yardımcı: Kaç mod max'a çıkarılmış?
-- -------------------------------------------------------
local function CountMaxedMods(changes, vehicle)
    local count = 0
    for _, c in ipairs(changes) do
        local maxMod = GetNumVehicleMods(vehicle, c.modType) - 1
        if maxMod >= 0 and c.newVal == maxMod then
            count = count + 1
        end
    end
    return count
end

-- -------------------------------------------------------
--  Modül kayıt
-- -------------------------------------------------------
RegisterACModule(MODULE_NAME, function()
    -- 5 saniyelik ana döngüde çağrılır
end)

-- -------------------------------------------------------
--  Server → Client: Mevcut aracı sil
--  Sunucu yetkisiz tuning tespit ettiğinde bu event tetiklenir
-- -------------------------------------------------------
RegisterNetEvent("anticheat:deleteCurrentVehicle")
AddEventHandler("anticheat:deleteCurrentVehicle", function()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle and vehicle ~= 0 then
        -- Önce oyuncuyu araçtan çıkar
        TaskLeaveVehicle(ped, vehicle, 16) -- 16 = teleport out
        Citizen.Wait(500)
        -- Aracı sil
        SetEntityAsMissionEntity(vehicle, false, true)
        DeleteEntity(vehicle)
    end
end)

-- -------------------------------------------------------
--  Ana tespit döngüsü
-- -------------------------------------------------------
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(CHECK_INTERVAL_MS)

        local ped = PlayerPedId()
        if not DoesEntityExist(ped) or IsEntityDead(ped) then
            goto continue
        end

        local vehicle = GetVehiclePedIsIn(ped, false)

        -- Araçta değilse → sıfırla
        if vehicle == 0 then
            if currentVehicle ~= 0 then
                currentVehicle = 0
                modSnapshot = {}
                windowTintSnapshot = -1
                tyresBurstSnapshot = true
            end
            goto continue
        end

        -- Yeni araca mı bindi?
        if vehicle ~= currentVehicle then
            currentVehicle = vehicle
            -- İlk snapshot al
            modSnapshot = TakeModSnapshot(vehicle)
            windowTintSnapshot = GetVehicleWindowTint(vehicle)
            tyresBurstSnapshot = GetVehicleTyresCanBurst(vehicle)
            goto continue
        end

        -- Aynı araçta — mod değişikliği kontrolü
        if currentVehicle ~= 0 and DoesEntityExist(currentVehicle) then
            local currentMods = TakeModSnapshot(currentVehicle)
            local changes = CompareSnapshots(modSnapshot, currentMods)

            -- Window tint değişikliği
            local currentTint = GetVehicleWindowTint(currentVehicle)
            local tintChanged = currentTint ~= windowTintSnapshot

            -- Tyre burst değişikliği
            local currentTyresBurst = GetVehicleTyresCanBurst(currentVehicle)
            local tyresChanged = currentTyresBurst ~= tyresBurstSnapshot

            -- Toplam değişiklik sayısı
            local totalChanges = #changes
            if tintChanged then totalChanges = totalChanges + 1 end
            if tyresChanged then totalChanges = totalChanges + 1 end

            -- Eşik kontrolü
            if totalChanges >= MOD_CHANGE_THRESHOLD then
                local now = GetGameTimer()
                if (now - lastReportTime) > COOLDOWN_MS then
                    lastReportTime = now

                    local maxedCount = CountMaxedMods(changes, currentVehicle)
                    local modelHash = GetEntityModel(currentVehicle)
                    local displayName = GetDisplayNameFromVehicleModel(modelHash) or "UNKNOWN"
                    local plate = GetVehicleNumberPlateText(currentVehicle) or "?"

                    local detail = string.format(
                        "Yetkisiz araç tuning tespiti!\n" ..
                        "Araç: %s [%s]\n" ..
                        "Toplam değişiklik: %d mod%s%s\n" ..
                        "Max'a çıkarılan: %d mod\n" ..
                        "Detay:\n%s",
                        displayName,
                        plate,
                        #changes,
                        tintChanged and " + cam filmi" or "",
                        tyresChanged and " + patlak lastik koruması" or "",
                        maxedCount,
                        FormatChanges(changes, currentVehicle)
                    )

                    -- Sunucuya bildir (meslek + admin kontrolü sunucuda yapılır)
                    TriggerServerEvent("anticheat:vehicleModDetected",
                        detail,
                        displayName,
                        plate,
                        totalChanges,
                        maxedCount
                    )
                end
            end

            -- Snapshot'ı güncelle (bir sonraki kontrol için)
            modSnapshot = currentMods
            windowTintSnapshot = currentTint
            tyresBurstSnapshot = currentTyresBurst
        end

        ::continue::
    end
end)
