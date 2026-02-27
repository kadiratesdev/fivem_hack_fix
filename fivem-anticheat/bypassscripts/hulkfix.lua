-- ============================================================
--  Bypass Modülü: hulkfix
--  HulkFix / benzeri bypass scriptlerini tespit eder.
--
--  Tespit yöntemleri:
--    1. Bilinen global değişken isimleri
--    2. Bilinen NativeDB bypass fonksiyon imzaları
--    3. Şüpheli native hook varlığı
-- ============================================================

-- Tespit edilecek global değişken / fonksiyon isimleri
local SUSPICIOUS_GLOBALS = {
    "HulkFix",
    "hulkfix",
    "HULKFIX",
    "HulkBypass",
    "hulk_bypass",
    "NativeBypass",
    "native_bypass",
    "BypassAC",
    "bypassAC",
    "bypass_ac",
    "AntiAntiCheat",
    "anti_anticheat",
}

-- Şüpheli native wrapper isimleri (bazı bypass'lar bunları override eder)
local SUSPICIOUS_NATIVE_WRAPPERS = {
    "Citizen_InvokeNative",
    "CitizenInvokeNative",
    "invokeNative",
    "invoke_native",
}

-- -------------------------------------------------------
-- Kontrol fonksiyonu
-- -------------------------------------------------------
local function CheckHulkFix()
    -- 1. Global değişken taraması
    for _, varName in ipairs(SUSPICIOUS_GLOBALS) do
        if _G[varName] ~= nil then
            ReportDetection("hulkfix", string.format("Şüpheli global bulundu: %s", varName))
            return
        end
    end

    -- 2. Native wrapper override kontrolü
    for _, wrapperName in ipairs(SUSPICIOUS_NATIVE_WRAPPERS) do
        if _G[wrapperName] ~= nil then
            ReportDetection("hulkfix", string.format("Native wrapper override tespit edildi: %s", wrapperName))
            return
        end
    end

    -- 3. Citizen.InvokeNative'in orijinal olup olmadığını kontrol et
    --    (Bazı bypass'lar Citizen tablosunu manipüle eder)
    if type(Citizen) ~= "table" then
        ReportDetection("hulkfix", "Citizen nesnesi manipüle edilmiş")
        return
    end

    if type(Citizen.InvokeNative) ~= "function" then
        ReportDetection("hulkfix", "Citizen.InvokeNative override edilmiş veya kaldırılmış")
        return
    end

    -- 4. Şüpheli resource listesi kontrolü
    --    (Oyuncunun tarafında çalışan kaynak isimlerini kontrol et)
    local suspiciousResourceNames = {
        "hulkfix", "hulk_fix", "hulk-fix",
        "bypassac", "bypass_ac", "bypass-ac",
        "nativebypass", "native_bypass",
    }

    -- Not: GetNumResources / GetResourceByFindIndex client-side'da çalışır
    local numResources = GetNumResources()
    for i = 0, numResources - 1 do
        local resName = GetResourceByFindIndex(i)
        if resName then
            local lowerName = string.lower(resName)
            for _, suspicious in ipairs(suspiciousResourceNames) do
                if lowerName:find(suspicious, 1, true) then
                    ReportDetection("hulkfix", string.format("Şüpheli kaynak tespit edildi: %s", resName))
                    return
                end
            end
        end
    end
end

-- -------------------------------------------------------
-- Modülü kaydet
-- -------------------------------------------------------
RegisterACModule("hulkfix", CheckHulkFix)
