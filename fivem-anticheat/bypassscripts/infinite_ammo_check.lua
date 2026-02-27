-- ============================================================
--  AntiCheat Modülü: infinite_ammo_check
--  Sınırsız mermi (infinite ammo) hile tespiti
--
--  Mantık:
--    1. Her döngüde oyuncunun elindeki silahın mermi sayısını takip et
--    2. Mermi sayısı bir önceki kontrole göre ARTTIYSA → şüpheli
--    3. Mermi sayısı Config.AmmoCheck.MaxAmmo üzerindeyse → kesin hile
--    4. Kısa sürede birden fazla artış tespiti → hile onayı
--
--  Hile yöntemi:
--    SetPedAmmo / SetAmmoInClip ile mermi 9999 yapılıyor
--    Bu native'ler ox_inventory'yi bypass eder
--
--  İstisnalar:
--    - Config.AmmoCheck.IgnoredWeapons listesindeki silahlar görmezden gelinir
--    - Silah değiştiğinde sayaç sıfırlanır (yeni silahın mermisi farklı olabilir)
-- ============================================================

RegisterACModule("infinite_ammo_check", function()
    local cfg = Config.AmmoCheck
    if not cfg then return end

    local ped = PlayerPedId()
    if not DoesEntityExist(ped) then return end

    local currentWeapon = GetSelectedPedWeapon(ped)

    -- Silah yoksa (unarmed) atla
    if currentWeapon == GetHashKey("WEAPON_UNARMED") or currentWeapon == 0 then
        -- Silah değişti, takibi sıfırla
        if _ammoTrack then
            _ammoTrack = nil
        end
        return
    end

    -- Mevcut mermi sayısını al
    local currentAmmo = GetAmmoInPedWeapon(ped, currentWeapon)

    -- -------------------------------------------------------
    -- 1. Kontrol: Maksimum mermi eşiği
    -- Mermi sayısı mantıksız derecede yüksekse → kesin hile
    -- -------------------------------------------------------
    if currentAmmo > cfg.MaxAmmo then
        -- Mermiyi sıfırla
        SetPedAmmo(ped, currentWeapon, 0)
        RemoveWeaponFromPed(ped, currentWeapon)

        local weaponName = _getWeaponName(currentWeapon) or tostring(currentWeapon)
        local reason = string.format("Sınırsız mermi tespiti: %s (mermi: %d, max: %d)",
            weaponName, currentAmmo, cfg.MaxAmmo)
        TriggerServerEvent("anticheat:ammoCheatDetected", weaponName, currentAmmo, reason)
        _ammoTrack = nil
        return
    end

    -- -------------------------------------------------------
    -- 2. Kontrol: Mermi artış takibi
    -- Aynı silahta mermi artıyorsa → şüpheli
    -- -------------------------------------------------------
    if not _ammoTrack then
        _ammoTrack = {
            weapon = currentWeapon,
            ammo = currentAmmo,
            strikes = 0,
            lastStrikeTime = 0,
        }
        return
    end

    -- Silah değiştiyse takibi sıfırla
    if _ammoTrack.weapon ~= currentWeapon then
        _ammoTrack = {
            weapon = currentWeapon,
            ammo = currentAmmo,
            strikes = 0,
            lastStrikeTime = 0,
        }
        return
    end

    -- IgnoredWeapons kontrolü
    if cfg.IgnoredWeapons then
        local weaponName = _getWeaponName(currentWeapon)
        if weaponName then
            for _, ignored in ipairs(cfg.IgnoredWeapons) do
                if string.lower(ignored) == weaponName then
                    return -- Bu silah muaf
                end
            end
        end
    end

    -- Mermi artış kontrolü
    local prevAmmo = _ammoTrack.ammo
    local now = GetGameTimer()

    if currentAmmo > prevAmmo then
        -- Mermi arttı! Bu şüpheli.
        -- Küçük artışları tolere et (oyun mekaniği, reload animasyonu vb.)
        -- Ama büyük artışlar veya tekrarlayan artışlar → hile
        local increase = currentAmmo - prevAmmo

        if increase >= cfg.SuspiciousIncrease then
            _ammoTrack.strikes = _ammoTrack.strikes + 1
            _ammoTrack.lastStrikeTime = now

            if _ammoTrack.strikes >= cfg.MaxStrikes then
                -- Yeterli sayıda şüpheli artış → hile onayı
                SetPedAmmo(ped, currentWeapon, 0)
                RemoveWeaponFromPed(ped, currentWeapon)

                local weaponName = _getWeaponName(currentWeapon) or tostring(currentWeapon)
                local reason = string.format(
                    "Mermi artış tespiti: %s (artış: %d→%d, %d ihlal)",
                    weaponName, prevAmmo, currentAmmo, _ammoTrack.strikes)
                TriggerServerEvent("anticheat:ammoCheatDetected", weaponName, currentAmmo, reason)
                _ammoTrack = nil
                return
            end
        end
    end

    -- Strike timeout: Belirli süre içinde yeni strike gelmezse sıfırla
    if _ammoTrack.strikes > 0 and (now - _ammoTrack.lastStrikeTime) > cfg.StrikeResetMs then
        _ammoTrack.strikes = 0
    end

    -- Mevcut mermi sayısını kaydet
    _ammoTrack.ammo = currentAmmo
end)

-- -------------------------------------------------------
-- Yardımcı: Weapon hash → isim çevirici
-- -------------------------------------------------------
function _getWeaponName(weaponHash)
    if not Config.WeaponCheck or not Config.WeaponCheck.WeaponHashMap then
        return nil
    end
    for name, _ in pairs(Config.WeaponCheck.WeaponHashMap) do
        if GetHashKey(name) == weaponHash then
            return string.lower(name)
        end
    end
    return nil
end

-- Takip değişkeni (modül scope)
_ammoTrack = nil
