-- ============================================================
--  AntiCheat Server: Vehicle Mod Detection Handler  v1.0.0
--
--  Yetkisiz araç tuning tespiti:
--    - Meslek kontrolü (mekanik, tuning, vb.)
--    - Admin bypass (ace permission)
--    - Araç silme + ban/kick
--    - Discord webhook loglama
--
--  Meslek kontrolü:
--    ESX: GetPlayerData().job.name
--    QBCore: GetPlayerData().job.name
--    Standalone: Config whitelist
--
--  İzin verilen meslekler Config'den yönetilir:
--    Config.VehicleModDetect.AllowedJobs = { "mechanic", "tuner", ... }
-- ============================================================

local _lastReport = {} -- [playerId] = timestamp

local cfg = Config.VehicleModDetect or {}
local ALLOWED_JOBS = cfg.AllowedJobs or { "mechanic", "tuner", "bennys" }

-- -------------------------------------------------------
--  Discord webhook log gönder
-- -------------------------------------------------------
local function SendModLog(playerId, playerName, detail, color)
    if not Config.LogWebhook or Config.LogWebhook == "" then
        print(string.format("^1[AntiCheat:VehicleMod] ^7%s (ID:%d): %s",
            playerName, playerId, detail))
        return
    end

    local embed = {
        {
            title = "🔧 Yetkisiz Araç Tuning Tespiti",
            description = detail,
            color = color or 16711680,
            fields = {
                { name = "Oyuncu",    value = playerName,                inline = true },
                { name = "ID",        value = tostring(playerId),        inline = true },
                { name = "Sunucu",    value = Config.ServerName or "?",  inline = true },
            },
            footer = {
                text = "AntiCheat VehicleMod v1.0.0 • " .. os.date("%Y-%m-%d %H:%M:%S"),
            },
        }
    }

    PerformHttpRequest(Config.LogWebhook, function() end, "POST", json.encode({
        username = "AntiCheat",
        embeds   = embed,
    }), { ["Content-Type"] = "application/json" })
end

-- -------------------------------------------------------
--  Admin bypass kontrolü
-- -------------------------------------------------------
local function IsAdmin(playerId)
    return IsPlayerAceAllowed(playerId, "anticheat.bypass")
end

-- -------------------------------------------------------
--  Meslek kontrolü
--  ESX ve QBCore framework'lerini destekler
--  Hiçbiri yoksa sadece Config whitelist kullanılır
-- -------------------------------------------------------
local function GetPlayerJob(playerId)
    -- ESX kontrolü
    local ESX = nil
    pcall(function()
        ESX = exports["es_extended"]:getSharedObject()
    end)
    if ESX then
        local xPlayer = ESX.GetPlayerFromId(playerId)
        if xPlayer then
            return xPlayer.getJob().name
        end
    end

    -- QBCore kontrolü
    local QBCore = nil
    pcall(function()
        QBCore = exports["qb-core"]:GetCoreObject()
    end)
    if QBCore then
        local player = QBCore.Functions.GetPlayer(playerId)
        if player then
            return player.PlayerData.job.name
        end
    end

    -- Framework bulunamadı
    return nil
end

-- -------------------------------------------------------
--  Meslek izin kontrolü
-- -------------------------------------------------------
local function IsAllowedJob(playerId)
    local job = GetPlayerJob(playerId)
    if not job then
        -- Framework yok → Config'deki UseJobCheck ayarına bak
        -- Framework yoksa meslek kontrolü yapılamaz
        if cfg.RequireFramework then
            return false -- Framework zorunlu ama yok → izin verme
        end
        return true -- Framework yok ve zorunlu değil → geç (sadece admin kontrolü)
    end

    for _, allowedJob in ipairs(ALLOWED_JOBS) do
        if job == allowedJob then
            return true
        end
    end
    return false
end

-- -------------------------------------------------------
--  Vehicle mod tespit event handler
-- -------------------------------------------------------
RegisterNetEvent("anticheat:vehicleModDetected")
AddEventHandler("anticheat:vehicleModDetected", function(detail, displayName, plate, totalChanges, maxedCount)
    local src = source
    local playerName = GetPlayerName(src) or "Bilinmiyor"

    -- Admin bypass
    if IsAdmin(src) then
        print(string.format("^3[AntiCheat:VehicleMod] ^7Admin bypass: %s (ID:%d)", playerName, src))
        return
    end

    -- Rate limiting: 15 saniyede bir
    local now = GetGameTimer()
    if _lastReport[src] and (now - _lastReport[src]) < 15000 then
        return
    end
    _lastReport[src] = now

    -- Meslek kontrolü
    if IsAllowedJob(src) then
        -- İzin verilen meslek — sadece log (uyarı seviyesi)
        local job = GetPlayerJob(src) or "unknown"
        SendModLog(src, playerName,
            string.format(
                "ℹ️ **Meslek izinli tuning**: %s (meslek: %s)\nAraç: %s [%s]\n%d mod değişikliği",
                playerName, job, displayName, plate, totalChanges
            ),
            3447003) -- Mavi (bilgi)
        return
    end

    -- Yetkisiz tuning!
    local job = GetPlayerJob(src) or "yok/bilinmiyor"

    local fullDetail = string.format(
        "🚨 **YETKİSİZ ARAÇ TUNİNG!**\n" ..
        "Oyuncu: %s (ID: %d)\n" ..
        "Meslek: %s (izinsiz)\n" ..
        "Araç: %s [%s]\n" ..
        "Değişiklik: %d mod, %d max'a çıkarılmış\n\n%s",
        playerName, src, job, displayName, plate,
        totalChanges, maxedCount, detail
    )

    -- Log gönder (kırmızı)
    SendModLog(src, playerName, fullDetail, 16711680)

    -- Aksiyon
    local action = Config.Action or "warn"

    if action == "ban" then
        -- Önce aracı sil (client'a komut gönder)
        TriggerClientEvent("anticheat:deleteCurrentVehicle", src)

        SendModLog(src, playerName,
            string.format("🔨 **BANNED**: Yetkisiz araç tuning\nAraç: %s [%s]", displayName, plate),
            16711680)

        -- Kısa gecikme ile ban (araç silme işlemi tamamlansın)
        Citizen.SetTimeout(1000, function()
            DropPlayer(src, string.format(Config.BanMessage, "Yetkisiz araç modifikasyonu"))
        end)

    elseif action == "kick" then
        TriggerClientEvent("anticheat:deleteCurrentVehicle", src)

        SendModLog(src, playerName,
            string.format("👢 **KICKED**: Yetkisiz araç tuning\nAraç: %s [%s]", displayName, plate),
            16744448) -- Turuncu

        Citizen.SetTimeout(1000, function()
            DropPlayer(src, "[AntiCheat] Yetkisiz araç modifikasyonu tespit edildi.")
        end)

    else
        -- Warn — aracı yine de sil ama ban/kick yapma
        TriggerClientEvent("anticheat:deleteCurrentVehicle", src)

        SendModLog(src, playerName,
            string.format("⚠️ **UYARI**: Yetkisiz araç tuning\nAraç: %s [%s]", displayName, plate),
            16776960) -- Sarı
    end
end)

-- -------------------------------------------------------
--  Oyuncu ayrıldığında temizlik
-- -------------------------------------------------------
AddEventHandler("playerDropped", function()
    _lastReport[source] = nil
end)
