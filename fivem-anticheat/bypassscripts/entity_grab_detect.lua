-- ============================================================
--  AntiCheat - Entity Grab / 7XCheat Detector
--  Tespit hedefi: MachoInjectResource ile inject edilen
--  entity grab/carry cheat scripti (7Xcheat / rollarcoaster anim)
-- ============================================================
--
--  Tespit İmzaları:
--  1. "anim@mp_rollarcoaster" animasyonu oynayan oyuncu
--     (Bu animasyon normal oyunda hiçbir mekanizma tarafından tetiklenmez)
--  2. "anim@heists@box_carry@" animasyonu oynarken
--     oyuncuya attach edilmiş bir vehicle veya ped varlığı
--  3. Oyuncuya attach edilmiş bir vehicle (araç) tespiti
--     (Normal oyunda araç oyuncuya attach edilemez)
-- ============================================================

local MODULE_NAME = "EntityGrabCheat"

-- Kontrol aralığı (ms)
local CHECK_INTERVAL = 1000

-- Kaç kez üst üste tespit edilirse aksiyon alınsın?
local DETECTION_THRESHOLD = 3

local detectionCount = 0

-- -------------------------------------------------------
-- Yardımcı: Oyuncuya attach edilmiş vehicle var mı?
-- -------------------------------------------------------
local function HasAttachedVehicle(ped)
    local pool = GetGamePool('CVehicle')
    for _, veh in ipairs(pool) do
        if IsEntityAttachedToEntity(veh, ped) then
            return true, veh
        end
    end
    return false, nil
end

-- -------------------------------------------------------
-- Yardımcı: Oyuncuya attach edilmiş ped var mı?
-- (Kendi ped'i hariç)
-- -------------------------------------------------------
local function HasAttachedPed(playerPed)
    local pool = GetGamePool('CPed')
    for _, ped in ipairs(pool) do
        if ped ~= playerPed and IsEntityAttachedToEntity(ped, playerPed) then
            return true, ped
        end
    end
    return false, nil
end

-- -------------------------------------------------------
-- Ana tespit döngüsü
-- -------------------------------------------------------
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(CHECK_INTERVAL)

        local playerPed = PlayerPedId()
        local detected  = false
        local reason    = ""

        -- İmza 1: anim@mp_rollarcoaster animasyonu
        -- Bu animasyon yalnızca cheat script tarafından tetiklenir.
        if IsEntityPlayingAnim(playerPed, 'anim@mp_rollarcoaster', 'hands_up_idle_a_player_one', 3) then
            detected = true
            reason   = "Yasak animasyon: anim@mp_rollarcoaster (entity grab cheat)"
        end

        -- İmza 2: anim@heists@box_carry@ oynarken attach edilmiş vehicle
        if not detected then
            local hasVeh, veh = HasAttachedVehicle(playerPed)
            if hasVeh then
                detected = true
                reason   = string.format("Oyuncuya attach edilmiş araç (entity: %d) - entity grab cheat", veh)
            end
        end

        -- İmza 3: anim@heists@box_carry@ oynarken attach edilmiş ped
        if not detected then
            if IsEntityPlayingAnim(playerPed, 'anim@heists@box_carry@', 'idle', 3) then
                local hasPed, attachedPed = HasAttachedPed(playerPed)
                if hasPed then
                    detected = true
                    reason   = string.format("Oyuncuya attach edilmiş ped (entity: %d) - entity grab cheat", attachedPed)
                end
            end
        end

        -- Tespit sayacı
        if detected then
            detectionCount = detectionCount + 1
            if detectionCount >= DETECTION_THRESHOLD then
                detectionCount = 0
                TriggerServerEvent("anticheat:detected", MODULE_NAME, reason)
            end
        else
            -- Yavaşça sıfırla (tek seferlik false positive'e karşı)
            if detectionCount > 0 then
                detectionCount = detectionCount - 1
            end
        end
    end
end)
