-- ============================================================
--  AntiCheat - Entity Grab / 7XCheat Detector
--  Tespit hedefi: MachoInjectResource ile inject edilen
--  entity grab/carry cheat scripti (7Xcheat / rollarcoaster anim)
-- ============================================================
--
--  Tespit İmzaları:
--  1. "anim@mp_rollarcoaster" animasyonu oynayan oyuncu
--     (Bu animasyon normal oyunda hiçbir mekanizma tarafından tetiklenmez)
--  2. Oyuncuya attach edilmiş bir vehicle (araç) tespiti
--     (Normal oyunda araç oyuncuya attach edilemez)
--
--  NOT: Ped taşıma tespiti kasıtlı olarak çıkarıldı.
--  Oyuncu normal gameplay'de başka bir pedi taşıyabilir
--  (örn. yaralı taşıma senaryoları). Yanlış pozitif riski yüksek.
-- ============================================================

local MODULE_NAME = "EntityGrabCheat"

-- Kontrol aralığı (ms)
local CHECK_INTERVAL = 1000

-- Kaç kez üst üste tespit edilirse aksiyon alınsın?
local DETECTION_THRESHOLD = 3

local detectionCount = 0

-- -------------------------------------------------------
-- Yardımcı: Oyuncuya attach edilmiş vehicle var mı?
-- Normal GTA V / FiveM'de bir araç oyuncu ped'ine
-- attach edilemez. Bu durum kesin hile imzasıdır.
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
        -- Normal GTA V / FiveM oynanışında hiçbir mekanizma bu animasyonu oynatmaz.
        if IsEntityPlayingAnim(playerPed, 'anim@mp_rollarcoaster', 'hands_up_idle_a_player_one', 3) then
            detected = true
            reason   = "Yasak animasyon: anim@mp_rollarcoaster (entity grab cheat)"
        end

        -- İmza 2: Oyuncuya attach edilmiş araç (vehicle)
        -- Normal oyunda bir araç oyuncu ped'ine attach edilemez.
        if not detected then
            local hasVeh, veh = HasAttachedVehicle(playerPed)
            if hasVeh then
                detected = true
                reason   = string.format("Oyuncuya attach edilmiş araç (entity: %d) - entity grab cheat", veh)
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
