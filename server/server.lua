-- ============================================================
--  AntiCheat - Server Side
--  Tüm ban/kick işlemleri burada yapılır.
-- ============================================================

local bannedPlayers = {} -- { [identifier] = { reason, expiry } }

-- -------------------------------------------------------
-- Yardımcı: Oyuncunun identifier'ını al
-- -------------------------------------------------------
local function GetPlayerIdentifier(source)
    -- Önce license, yoksa steam, yoksa discord
    local ids = { "license", "steam", "discord", "ip" }
    for _, idType in ipairs(ids) do
        local id = GetPlayerIdentifierByType(source, idType)
        if id then return id end
    end
    return tostring(source)
end

-- -------------------------------------------------------
-- Yardımcı: Discord webhook log
-- -------------------------------------------------------
local function SendLog(msg)
    print("[AntiCheat] " .. msg)
    if Config.LogWebhook and Config.LogWebhook ~= "" then
        PerformHttpRequest(Config.LogWebhook, function() end, "POST",
            json.encode({
                username = Config.ServerName .. " AntiCheat",
                embeds = {{
                    title  = "🚨 AntiCheat Tespit",
                    description = msg,
                    color  = 16711680,
                    footer = { text = os.date("%Y-%m-%d %H:%M:%S") }
                }}
            }),
            { ["Content-Type"] = "application/json" }
        )
    end
end

-- -------------------------------------------------------
-- Ban uygula
-- -------------------------------------------------------
local function BanPlayer(source, reason)
    local identifier = GetPlayerIdentifier(source)
    local name       = GetPlayerName(source) or "Unknown"
    local expiry     = Config.BanDuration == 0 and 0 or (os.time() + Config.BanDuration * 60)

    bannedPlayers[identifier] = { reason = reason, expiry = expiry }

    local msg = string.format("BAN | Oyuncu: %s (%s) | Sebep: %s", name, identifier, reason)
    SendLog(msg)

    DropPlayer(source, string.format(Config.BanMessage, reason))
end

-- -------------------------------------------------------
-- Kick uygula
-- -------------------------------------------------------
local function KickPlayer(source, reason)
    local identifier = GetPlayerIdentifier(source)
    local name       = GetPlayerName(source) or "Unknown"
    local msg        = string.format("KICK | Oyuncu: %s (%s) | Sebep: %s", name, identifier, reason)
    SendLog(msg)
    DropPlayer(source, "[AntiCheat] Sunucudan atıldınız. Sebep: " .. reason)
end

-- -------------------------------------------------------
-- Ban kontrolü (oyuncu bağlandığında)
-- -------------------------------------------------------
AddEventHandler("playerConnecting", function(name, setKickReason, deferrals)
    local source     = source
    local identifier = GetPlayerIdentifier(source)

    deferrals.defer()
    Citizen.Wait(0)

    if bannedPlayers[identifier] then
        local ban = bannedPlayers[identifier]
        if ban.expiry == 0 or ban.expiry > os.time() then
            deferrals.done("[AntiCheat] Banlandınız. Sebep: " .. ban.reason)
            return
        else
            -- Süre dolmuş, ban kaldır
            bannedPlayers[identifier] = nil
        end
    end

    deferrals.done()
end)

-- -------------------------------------------------------
-- CLIENT → SERVER: Tespit eventi (client'tan gelen)
-- -------------------------------------------------------
RegisterNetEvent("anticheat:detected")
AddEventHandler("anticheat:detected", function(moduleName, detail)
    local source = source
    local reason = string.format("[%s] %s", moduleName, detail or "Bypass script tespit edildi")

    if Config.Action == "ban" then
        BanPlayer(source, reason)
    elseif Config.Action == "kick" then
        KickPlayer(source, reason)
    else
        local name = GetPlayerName(source) or "Unknown"
        local id   = GetPlayerIdentifier(source)
        SendLog(string.format("WARN | %s (%s) | %s", name, id, reason))
    end
end)

-- -------------------------------------------------------
-- SERVER → SERVER: Dahili ban eventi
-- weapon_check_server.lua gibi diğer server modülleri kullanır
-- -------------------------------------------------------
AddEventHandler("anticheat:internalBan", function(source, reason)
    if Config.Action == "ban" then
        BanPlayer(source, reason)
    elseif Config.Action == "kick" then
        KickPlayer(source, reason)
    else
        local name = GetPlayerName(source) or "Unknown"
        local id   = GetPlayerIdentifier(source)
        SendLog(string.format("WARN | %s (%s) | %s", name, id, reason))
    end
end)

-- -------------------------------------------------------
-- SERVER → CLIENT: Manuel ban komutu (admin)
-- -------------------------------------------------------
RegisterCommand("acban", function(source, args, rawCommand)
    -- Sadece sunucu konsolundan veya yetkili oyuncudan
    if source ~= 0 then
        -- Burada kendi yetki sisteminizi kontrol edebilirsiniz
        -- Örnek: if not IsPlayerAceAllowed(source, "anticheat.ban") then return end
    end

    local targetId = tonumber(args[1])
    local reason   = table.concat(args, " ", 2) or "Admin ban"

    if not targetId then
        print("[AntiCheat] Kullanım: /acban <playerID> <sebep>")
        return
    end

    BanPlayer(targetId, reason)
end, true)

-- -------------------------------------------------------
-- Başlangıç logu
-- -------------------------------------------------------
AddEventHandler("onResourceStart", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        print("^2[AntiCheat] ^7Sistem başlatıldı. Modüller yükleniyor...")
    end
end)
