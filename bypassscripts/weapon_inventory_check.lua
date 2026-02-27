-- ============================================================
--  AntiCheat Modülü: weapon_inventory_check
--  ox_inventory client export ile silah tespiti
--
--  Mantık:
--    1. Oyuncunun elindeki silahı al (GetSelectedPedWeapon)
--    2. exports.ox_inventory:GetPlayerItems() ile tüm envanter
--       itemlerini tek seferde al
--    3. Silah item'ı envanterde yoksa → silahı al + sunucuya bildir
--
--  İstisnalar:
--    - Config.WeaponCheck.IgnoredWeapons listesindeki silahlar görmezden gelinir
--    - Config.WeaponCheck.IgnoredZones içindeki bölgelerde kontrol çalışmaz
-- ============================================================

RegisterACModule("weapon_inventory_check", function()
    local cfg = Config.WeaponCheck

    -- Oyuncu yüklü değilse atla
    local ped = PlayerPedId()
    if not DoesEntityExist(ped) then return end

    -- Elindeki silahı al
    local currentWeapon = GetSelectedPedWeapon(ped)

    -- Silah yoksa (unarmed) atla
    if currentWeapon == GetHashKey("WEAPON_UNARMED") or currentWeapon == 0 then
        return
    end

    -- Silah hash'ini item adına çevir (WeaponHashMap üzerinden)
    local weaponName = nil
    for name, _ in pairs(cfg.WeaponHashMap) do
        if GetHashKey(name) == currentWeapon then
            weaponName = string.lower(name)
            break
        end
    end

    -- Hash map'te bulunamadıysa → bilinmeyen silah, şüpheli
    if not weaponName then
        ReportDetection("weapon_inventory_check",
            string.format("Bilinmeyen silah hash tespit edildi: %s", tostring(currentWeapon)))
        return
    end

    -- IgnoredWeapons listesinde mi?
    for _, ignored in ipairs(cfg.IgnoredWeapons) do
        if string.lower(ignored) == weaponName then
            return -- Bu silah muaf, kontrol etme
        end
    end

    -- IgnoredZones kontrolü
    local playerCoords = GetEntityCoords(ped)
    for _, zone in ipairs(cfg.IgnoredZones) do
        local dist = #(playerCoords - vector3(zone.x, zone.y, zone.z))
        if dist <= zone.radius then
            return -- Bu bölgede kontrol çalışmaz
        end
    end

    -- ✅ ox_inventory:GetPlayerItems() ile tüm envanter itemlerini al
    -- Tek bir export çağrısı ile tüm itemler gelir, sonra table lookup yaparız
    local items = exports.ox_inventory:GetPlayerItems()

    if items then
        for _, item in pairs(items) do
            if item.name and string.lower(item.name) == weaponName and item.count and item.count > 0 then
                -- Silah envanterde mevcut, sorun yok
                return
            end
        end
    end

    -- Silah envanterde YOK ama elde var → hile!
    -- Önce silahı client'ta zorla kaldır
    RemoveWeaponFromPed(ped, currentWeapon)

    -- Sunucuya bildir (ban/kick/warn için)
    local reason = string.format("Envanterde olmayan silah: %s", weaponName)
    TriggerServerEvent("anticheat:weaponCheatDetected", weaponName, currentWeapon, reason)
end)
