-- ============================================================
--  AntiCheat - Client Ana Döngü
--  Kayıtlı tüm modülleri periyodik olarak çalıştırır
-- ============================================================

local CHECK_INTERVAL = 5000 -- ms (her 5 saniyede bir kontrol)

-- -------------------------------------------------------
-- Ana kontrol döngüsü
-- -------------------------------------------------------
Citizen.CreateThread(function()
    -- Kaynak tamamen yüklenene kadar bekle
    Citizen.Wait(3000)

    print("^2[AntiCheat] ^7Client başlatıldı. Aktif modül sayısı: " .. (function()
        local c = 0
        for _ in pairs(ACModules) do c = c + 1 end
        return c
    end)())

    while true do
        Citizen.Wait(CHECK_INTERVAL)

        -- Oyuncu yüklenmediyse atla
        if not NetworkIsPlayerActive(PlayerId()) then
            goto continue
        end

        -- Tüm kayıtlı modülleri çalıştır
        for moduleName, checkFn in pairs(ACModules) do
            local ok, err = pcall(checkFn)
            if not ok then
                -- Modül hata verdi, logla ama çökme
                print(string.format("^1[AntiCheat] ^7Modül hatası [%s]: %s", moduleName, tostring(err)))
            end
        end

        ::continue::
    end
end)

-- -------------------------------------------------------
-- Sunucudan gelen bildirim (opsiyonel UI mesajı)
-- -------------------------------------------------------
RegisterNetEvent("anticheat:notify")
AddEventHandler("anticheat:notify", function(msg)
    -- Ekrana bildirim göster (isteğe bağlı)
    SetNotificationTextEntry("STRING")
    AddTextComponentString("~r~[AntiCheat] ~w~" .. msg)
    DrawNotification(false, true)
end)
