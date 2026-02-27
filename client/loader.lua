-- ============================================================
--  AntiCheat - Client Modül Loader
--  bypassscripts/ altındaki modülleri Config'e göre yükler
-- ============================================================

-- Modül kayıt tablosu
ACModules = {}

-- -------------------------------------------------------
-- Modül kayıt fonksiyonu (her modül bu fonksiyonu çağırır)
-- -------------------------------------------------------
function RegisterACModule(name, checkFn)
    if not Config.Modules[name] then
        -- Config'de kapalıysa yükleme
        return
    end
    ACModules[name] = checkFn
    print(string.format("^3[AntiCheat] ^7Modül yüklendi: %s", name))
end

-- -------------------------------------------------------
-- Sunucuya tespit bildirimi gönder
-- -------------------------------------------------------
function ReportDetection(moduleName, detail)
    TriggerServerEvent("anticheat:detected", moduleName, detail)
end
