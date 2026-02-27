-- ============================================================
--  AntiCheat Modülü: infinite_ammo_check  (v1.3.0)
--  Sınırsız mermi (infinite ammo) hile tespiti
--
--  Mantık:
--    1. Mermi artışı kontrolü:
--       - Bir şarjör en fazla ~50 mermi artırır (reload)
--       - 50'den fazla tek seferlik artış → kesin hile
--       - Tekrarlayan şüpheli artışlar → hile onayı
--
--    2. Sabit mermi (stale ammo) kontrolü:
--       - Oyuncu ateş ediyor ama mermi sayısı hiç düşmüyorsa
--       - Belirli sayıda ateş döngüsünden sonra hâlâ aynıysa → şüpheli
--       - Bu durum SADECE loglanır, ban atılmaz
--       - Silah elinden alınıp envantere geri konur
--
--    3. Maksimum mermi eşiği:
--       - Mermi sayısı Config.AmmoCheck.MaxAmmo üzerindeyse → kesin hile
--
--  Aksiyon:
--    - Hile tespitinde silah elinden alınır (envantere geri döner)
--    - Ban/kick yerine silah kaldırma + log
--
--  İstisnalar:
--    - Config.AmmoCheck.IgnoredWeapons listesindeki silahlar muaf
--    - Silah değiştiğinde sayaç sıfırlanır
-- ============================================================

RegisterACModule("infinite_ammo_check", function()
    local cfg = Config.AmmoCheck
    if not cfg then return end

    local ped = PlayerPedId()
    if not DoesEntityExist(ped) then return end

    local currentWeapon = GetSelectedPedWeapon(ped)

    -- Silah yoksa (unarmed) atla
    if currentWeapon == GetHashKey("WEAPON_UNARMED") or currentWeapon == 0 then
        if _ammoTrack then
            _ammoTrack = nil
        end
        return
    end

    -- IgnoredWeapons kontrolü (erken çık)
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

    -- Mevcut mermi sayısını al
    local currentAmmo = GetAmmoInPedWeapon(ped, currentWeapon)

    -- -------------------------------------------------------
    -- Yardımcı: Silahı elinden al (envantere geri döner)
    -- ox_inventory kullanıyorsa silah otomatik envantere döner
    -- -------------------------------------------------------
    local function confiscateWeapon(weaponHash)
        SetPedAmmo(ped, weaponHash, 0)
        RemoveWeaponFromPed(ped, weaponHash)
        -- ox_inventory entegrasyonu: silah envantere geri döner
        -- RemoveWeaponFromPed ox_inventory ile uyumlu çalışır
    end

    -- -------------------------------------------------------
    -- 1. Kontrol: Maksimum mermi eşiği
    -- Mermi sayısı mantıksız derecede yüksekse → kesin hile
    -- -------------------------------------------------------
    if currentAmmo > cfg.MaxAmmo then
        confiscateWeapon(currentWeapon)

        local weaponName = _getWeaponName(currentWeapon) or tostring(currentWeapon)
        local reason = string.format("Sınırsız mermi tespiti: %s (mermi: %d, max: %d)",
            weaponName, currentAmmo, cfg.MaxAmmo)
        TriggerServerEvent("anticheat:ammoCheatDetected", weaponName, currentAmmo, reason)
        _ammoTrack = nil
        return
    end

    -- -------------------------------------------------------
    -- 2. Takip başlat / silah değişimi kontrolü
    -- -------------------------------------------------------
    if not _ammoTrack then
        _ammoTrack = {
            weapon = currentWeapon,
            ammo = currentAmmo,
            strikes = 0,
            lastStrikeTime = 0,
            staleCount = 0,       -- Sabit mermi sayacı
            wasShooting = false,   -- Önceki döngüde ateş ediyor muydu
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
            staleCount = 0,
            wasShooting = false,
        }
        return
    end

    local prevAmmo = _ammoTrack.ammo
    local now = GetGameTimer()

    -- -------------------------------------------------------
    -- 3. Kontrol: Mermi artış kontrolü
    -- Bir şarjör en fazla ~50 mermi artırır
    -- 50'den fazla artış → kesin hile (tek seferde)
    -- -------------------------------------------------------
    if currentAmmo > prevAmmo then
        local increase = currentAmmo - prevAmmo

        -- Tek seferde 50'den fazla artış → kesin hile
        if increase > cfg.MaxMagazineSize then
            confiscateWeapon(currentWeapon)

            local weaponName = _getWeaponName(currentWeapon) or tostring(currentWeapon)
            local reason = string.format(
                "Şarjör limiti aşıldı: %s (artış: +%d, max şarjör: %d, %d→%d)",
                weaponName, increase, cfg.MaxMagazineSize, prevAmmo, currentAmmo)
            TriggerServerEvent("anticheat:ammoCheatDetected", weaponName, currentAmmo, reason)
            _ammoTrack = nil
            return
        end

        -- Normal şarjör aralığında ama yine de şüpheli artış (tekrarlayan)
        if increase >= cfg.SuspiciousIncrease then
            _ammoTrack.strikes = _ammoTrack.strikes + 1
            _ammoTrack.lastStrikeTime = now

            if _ammoTrack.strikes >= cfg.MaxStrikes then
                confiscateWeapon(currentWeapon)

                local weaponName = _getWeaponName(currentWeapon) or tostring(currentWeapon)
                local reason = string.format(
                    "Tekrarlayan mermi artışı: %s (son artış: +%d, %d ihlal)",
                    weaponName, increase, _ammoTrack.strikes)
                TriggerServerEvent("anticheat:ammoCheatDetected", weaponName, currentAmmo, reason)
                _ammoTrack = nil
                return
            end
        end

        -- Stale count sıfırla (mermi değişti)
        _ammoTrack.staleCount = 0
    end

    -- -------------------------------------------------------
    -- 4. Kontrol: Sabit mermi (stale ammo) tespiti
    -- Oyuncu ateş ediyor ama mermi hiç düşmüyorsa → şüpheli
    -- Bu durum SADECE loglanır, ban atılmaz
    -- Silah elinden alınır
    -- -------------------------------------------------------
    local isShooting = IsPedShooting(ped)

    if isShooting and currentAmmo == prevAmmo and prevAmmo > 0 then
        -- Ateş ediyor ama mermi düşmüyor
        _ammoTrack.staleCount = _ammoTrack.staleCount + 1

        if _ammoTrack.staleCount >= cfg.StaleAmmoThreshold then
            confiscateWeapon(currentWeapon)

            local weaponName = _getWeaponName(currentWeapon) or tostring(currentWeapon)
            local reason = string.format(
                "Sabit mermi şüphesi: %s (mermi: %d, %d döngü boyunca değişmedi)",
                weaponName, currentAmmo, _ammoTrack.staleCount)
            -- Özel event: sadece log, ban yok
            TriggerServerEvent("anticheat:ammoSuspicious", weaponName, currentAmmo, reason)
            _ammoTrack = nil
            return
        end
    elseif not isShooting then
        -- Ateş etmiyorsa stale sayacını sıfırla
        -- (sadece ateş ederken sabit kalması şüpheli)
        _ammoTrack.staleCount = 0
    end

    -- -------------------------------------------------------
    -- Strike timeout: Belirli süre içinde yeni strike gelmezse sıfırla
    -- -------------------------------------------------------
    if _ammoTrack and _ammoTrack.strikes > 0 and (now - _ammoTrack.lastStrikeTime) > cfg.StrikeResetMs then
        _ammoTrack.strikes = 0
    end

    -- Mevcut mermi sayısını kaydet
    if _ammoTrack then
        _ammoTrack.ammo = currentAmmo
    end
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
