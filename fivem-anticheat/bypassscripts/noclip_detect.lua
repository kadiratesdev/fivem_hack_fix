-- ============================================================
--  Bypass Modülü: noclip_detect
--  NoClip / uçma hilesi tespiti
--
--  Tespit yöntemleri:
--    1. Oyuncunun yerde olmadığı halde hız vektörü sıfır
--    2. Collision devre dışı bırakılmış
--    3. Şüpheli yükseklik değişimi
-- ============================================================

local lastZ         = nil
local lastCheckTime = 0
local SUSPICIOUS_Z_DELTA = 10.0 -- 1 kontrol aralığında 10 birim yükselme şüpheli

local function CheckNoClip()
    local ped = PlayerPedId()
    if not DoesEntityExist(ped) then return end

    -- Araçtaysa atla
    if IsPedInAnyVehicle(ped, false) then
        lastZ = nil
        return
    end

    -- Ragdoll / düşme durumunda atla
    if IsPedRagdoll(ped) or IsPedFalling(ped) then
        lastZ = nil
        return
    end

    local coords = GetEntityCoords(ped)
    local now    = GetGameTimer()

    -- Collision kontrolü
    if not GetEntityCollisionDisabled(ped) == false then
        -- Collision kapalı ama yerde değil
        if not IsEntityOnGround(ped) then
            ReportDetection("noclip_detect", "Entity collision devre dışı ve havada")
            return
        end
    end

    -- Z ekseni hızlı değişim kontrolü
    if lastZ ~= nil then
        local delta = math.abs(coords.z - lastZ)
        if delta > SUSPICIOUS_Z_DELTA then
            ReportDetection("noclip_detect", string.format(
                "Şüpheli Z değişimi: %.2f birim (%.2f -> %.2f)",
                delta, lastZ, coords.z
            ))
            lastZ = coords.z
            return
        end
    end

    lastZ = coords.z
end

-- -------------------------------------------------------
-- Modülü kaydet (Config.Modules'da "noclip_detect = true" olmalı)
-- -------------------------------------------------------
RegisterACModule("noclip_detect", CheckNoClip)
