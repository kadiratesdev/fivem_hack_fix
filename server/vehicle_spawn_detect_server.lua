-- ============================================================
--  AntiCheat Server: Vehicle Spawn Detection Handler  v1.0.0
--
--  Yetkisiz araç spawn tespiti:
--    - Whitelist sistemi: Meşru scriptler araç spawn'ını kaydeder
--    - Hızlı spawn tespiti: Kısa sürede çok araç = hile
--    - Araç doğrulama: Client bildirimi vs sunucu kaydı
--    - Discord webhook loglama
--    - Admin bypass
--
--  Whitelist Entegrasyonu:
--    Garaj, dealer, admin spawn gibi meşru scriptler şu
--    server event'i tetikleyerek araçları whitelist'e ekler:
--
--    TriggerEvent("anticheat:authorizeVehicle", source, netId, reason)
--
--    Örnek (garaj scriptinizde):
--    TriggerEvent("anticheat:authorizeVehicle", source, netId, "garage_spawn")
-- ============================================================

local _lastReport = {}          -- [playerId] = timestamp (rate limiting)
local _authorizedVehicles = {}  -- [netId] = { playerId, reason, timestamp }
local _playerSpawnLog = {}      -- [playerId] = { { timestamp, model, plate } }

local cfg = Config.VehicleSpawnDetect or {}
local AUTH_EXPIRE_MS     = cfg.AuthExpireMs or 30000      -- Whitelist kaydı 30sn sonra silinir
local MAX_SPAWNS_SERVER  = cfg.MaxSpawnsServer or 5       -- Sunucu tarafı hızlı spawn eşiği
local SPAWN_WINDOW_MS    = cfg.SpawnWindowMs or 60000     -- 60 saniyelik pencere

-- -------------------------------------------------------
--  Discord webhook log gönder
-- -------------------------------------------------------
local function SendVehicleLog(playerId, playerName, detail, color)
    if not Config.LogWebhook or Config.LogWebhook == "" then
        print(string.format("^1[AntiCheat:VehicleSpawn] ^7%s (ID:%d): %s",
            playerName, playerId, detail))
        return
    end

    local embed = {
        {
            title = "🚗 Yetkisiz Araç Spawn Tespiti",
            description = detail,
            color = color or 16711680,
            fields = {
                { name = "Oyuncu",    value = playerName,                inline = true },
                { name = "ID",        value = tostring(playerId),        inline = true },
                { name = "Sunucu",    value = Config.ServerName or "?",  inline = true },
            },
            footer = {
                text = "AntiCheat VehicleSpawn v1.0.0 • " .. os.date("%Y-%m-%d %H:%M:%S"),
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
--  Eski whitelist kayıtlarını temizle
-- -------------------------------------------------------
local function CleanExpiredAuth()
    local now = GetGameTimer()
    for netId, data in pairs(_authorizedVehicles) do
        if (now - data.timestamp) > AUTH_EXPIRE_MS then
            _authorizedVehicles[netId] = nil
        end
    end
end

-- -------------------------------------------------------
--  Oyuncu spawn logunu temizle (eski kayıtlar)
-- -------------------------------------------------------
local function CleanPlayerSpawnLog(playerId)
    if not _playerSpawnLog[playerId] then return end
    local now = GetGameTimer()
    local cleaned = {}
    for _, entry in ipairs(_playerSpawnLog[playerId]) do
        if (now - entry.timestamp) < SPAWN_WINDOW_MS then
            cleaned[#cleaned + 1] = entry
        end
    end
    _playerSpawnLog[playerId] = cleaned
end

-- -------------------------------------------------------
--  WHITELIST API: Meşru scriptler bu event'i tetikler
--
--  Kullanım (garaj/dealer/admin scriptinizde):
--    TriggerEvent("anticheat:authorizeVehicle", source, netId, "garage")
-- -------------------------------------------------------
AddEventHandler("anticheat:authorizeVehicle", function(playerId, netId, reason)
    _authorizedVehicles[netId] = {
        playerId  = playerId,
        reason    = reason or "authorized",
        timestamp = GetGameTimer(),
    }
end)

-- -------------------------------------------------------
--  Client → Server: Yakında yeni araç tespit edildi
--  Client her yeni araç gördüğünde bunu tetikler
-- -------------------------------------------------------
RegisterNetEvent("anticheat:vehicleSpawnCheck")
AddEventHandler("anticheat:vehicleSpawnCheck", function(netId, displayName, plate, distance)
    local src = source
    local playerName = GetPlayerName(src) or "Bilinmiyor"

    -- Admin bypass
    if IsAdmin(src) then return end

    -- Rate limiting
    local now = GetGameTimer()
    if _lastReport[src] and (now - _lastReport[src]) < 5000 then
        return
    end
    _lastReport[src] = now

    -- Eski whitelist kayıtlarını temizle
    CleanExpiredAuth()

    -- Whitelist kontrolü
    if netId and netId > 0 and _authorizedVehicles[netId] then
        -- Meşru araç, geç
        return
    end

    -- Spawn log'a ekle
    if not _playerSpawnLog[src] then
        _playerSpawnLog[src] = {}
    end
    _playerSpawnLog[src][#_playerSpawnLog[src] + 1] = {
        timestamp = now,
        model = displayName,
        plate = plate,
        distance = distance,
    }

    -- Çok yakın mesafede spawn (< 3m) = çok şüpheli
    if distance and distance < 3.0 then
        SendVehicleLog(src, playerName,
            string.format(
                "⚠️ **Şüpheli araç spawn**: %s [%s]\nMesafe: %.1fm (çok yakın!)\nNetID: %s",
                displayName, plate, distance, tostring(netId)
            ),
            16776960) -- Sarı
    end

    -- Sunucu tarafı hızlı spawn kontrolü
    CleanPlayerSpawnLog(src)
    local spawnCount = #_playerSpawnLog[src]

    if spawnCount >= MAX_SPAWNS_SERVER then
        -- Kesin hile: Çok fazla araç spawn
        local spawnList = {}
        for _, entry in ipairs(_playerSpawnLog[src]) do
            spawnList[#spawnList + 1] = string.format(
                "%s [%s] (%.1fm)",
                entry.model, entry.plate, entry.distance or 0
            )
        end

        local detail = string.format(
            "🚨 **Hızlı araç spawn tespiti!**\n%d araç / %d saniye:\n%s",
            spawnCount,
            SPAWN_WINDOW_MS / 1000,
            table.concat(spawnList, "\n")
        )

        SendVehicleLog(src, playerName, detail, 16711680) -- Kırmızı

        -- Aksiyon
        local action = Config.Action or "warn"
        if action == "ban" then
            DropPlayer(src, string.format(Config.BanMessage, "Yetkisiz araç spawn (hızlı spawn)"))
        elseif action == "kick" then
            DropPlayer(src, "[AntiCheat] Yetkisiz araç spawn tespit edildi.")
        end

        -- Log temizle (tekrar tetiklemesin)
        _playerSpawnLog[src] = {}
    end
end)

-- -------------------------------------------------------
--  Client → Server: Oyuncu araca bindi — doğrulama
-- -------------------------------------------------------
RegisterNetEvent("anticheat:vehicleEntered")
AddEventHandler("anticheat:vehicleEntered", function(netId, displayName, plate)
    local src = source
    local playerName = GetPlayerName(src) or "Bilinmiyor"

    -- Admin bypass
    if IsAdmin(src) then return end

    -- Eski whitelist kayıtlarını temizle
    CleanExpiredAuth()

    -- Whitelist kontrolü
    if netId and netId > 0 and _authorizedVehicles[netId] then
        return -- Meşru araç
    end

    -- netId 0 ise (networked değil) = client-only araç = çok şüpheli
    if not netId or netId == 0 then
        SendVehicleLog(src, playerName,
            string.format(
                "🚨 **Network dışı araca biniş!**\nAraç: %s [%s]\nBu araç sunucuda kayıtlı değil (client-only spawn olabilir)",
                displayName, plate
            ),
            16711680) -- Kırmızı

        local action = Config.Action or "warn"
        if action == "ban" then
            DropPlayer(src, string.format(Config.BanMessage, "Yetkisiz araç (network dışı)"))
        elseif action == "kick" then
            DropPlayer(src, "[AntiCheat] Yetkisiz araç tespit edildi.")
        end
        return
    end

    -- Araç whitelist'te değil ama networked = log (uyarı seviyesi)
    -- Bu durum bazen meşru olabilir (başka oyuncunun aracı, sokak aracı vb.)
    -- Sadece logla, aksiyon alma
    -- print(string.format("^3[AntiCheat:VehicleSpawn] ^7%s (ID:%d) araca bindi: %s [%s] (netId:%d) - whitelist'te yok",
    --     playerName, src, displayName, plate, netId))
end)

-- -------------------------------------------------------
--  Client → Server: Hızlı spawn tespiti (client tarafından)
-- -------------------------------------------------------
RegisterNetEvent("anticheat:vehicleSpawnDetected")
AddEventHandler("anticheat:vehicleSpawnDetected", function(detail)
    local src = source
    local playerName = GetPlayerName(src) or "Bilinmiyor"

    -- Admin bypass
    if IsAdmin(src) then return end

    -- Rate limiting: 30 saniyede bir
    local now = GetGameTimer()
    local key = "detected_" .. tostring(src)
    if _lastReport[key] and (now - _lastReport[key]) < 30000 then
        return
    end
    _lastReport[key] = now

    SendVehicleLog(src, playerName, detail, 16744448) -- Turuncu

    local action = Config.Action or "warn"
    if action == "ban" then
        DropPlayer(src, string.format(Config.BanMessage, "Yetkisiz araç spawn (çoklu spawn)"))
    elseif action == "kick" then
        DropPlayer(src, "[AntiCheat] Yetkisiz araç spawn tespit edildi.")
    end
end)

-- -------------------------------------------------------
--  Oyuncu ayrıldığında temizlik
-- -------------------------------------------------------
AddEventHandler("playerDropped", function()
    local src = source
    _lastReport[src] = nil
    _lastReport["detected_" .. tostring(src)] = nil
    _playerSpawnLog[src] = nil
end)

-- -------------------------------------------------------
--  Periyodik whitelist temizliği (5 dakikada bir)
-- -------------------------------------------------------
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(300000) -- 5 dakika
        CleanExpiredAuth()
    end
end)
