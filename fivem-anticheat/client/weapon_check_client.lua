-- ============================================================
--  AntiCheat - Silah Zorla Kaldırma (Client Side)
--  Sunucudan gelen komutla oyuncunun elindeki silahı kaldırır
-- ============================================================

RegisterNetEvent("anticheat:forceRemoveWeapon")
AddEventHandler("anticheat:forceRemoveWeapon", function(weaponHash)
    local ped = PlayerPedId()
    if DoesEntityExist(ped) then
        RemoveWeaponFromPed(ped, weaponHash)
        -- Bildirim göster
        SetNotificationTextEntry("STRING")
        AddTextComponentString("~r~[AntiCheat] ~w~Yetkisiz silah tespit edildi ve kaldırıldı.")
        DrawNotification(false, true)
    end
end)
