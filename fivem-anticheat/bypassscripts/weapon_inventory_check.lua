-- ============================================================
--  AntiCheat Modülü: weapon_inventory_check
--  ox_inventory entegrasyonu ile silah tespiti
--
--  Mantık:
--    1. Oyuncunun elindeki silahı al (GetSelectedPedWeapon)
--    2. ox_inventory'den oyuncunun envanterini sorgula
--    3. Eğer eldeki silah envanterde yoksa → silahı al + ban
--
--  İstisnalar:
--    - Config.WeaponCheck.IgnoredWeapons listesindeki silahlar görmezden gelinir
--      (paintball, etkinlik silahları vb.)
--    - Config.WeaponCheck.IgnoredZones içindeki koordinat bölgelerinde kontrol çalışmaz
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

    -- Silah hash'ini string'e çevir (ox_inventory item adı için)
    local weaponName = nil
    for name, hash in pairs(cfg.WeaponHashMap) do
        if GetHashKey(name) == currentWeapon then
            weaponName = string.lower(name)
            break
        end
    end

    -- Hash map'te bulunamadıysa GetWeaponName ile dene
    if not weaponName then
        -- Bilinmeyen silah hash'i → şüpheli, raporla
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

    -- ox_inventory'den envanter kontrolü (server-side callback)
    TriggerServerEvent("anticheat:checkWeaponInventory", weaponName, currentWeapon)
end)
