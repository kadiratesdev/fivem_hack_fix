-- ============================================================
--  AntiCheat - Player Attach / Invisible Attach Detector v1.0.0
--
--  Tespit hedefi: Oyuncunun başka bir oyuncuya görünmez olarak
--  yapışması (attach) — "ghost attach" / "invisible follow" cheat
--
--  Cheat imzası:
--    1. AttachEntityToEntity ile hedef oyuncuya yapışma
--    2. SetEntityVisible(ped, false) ile görünmez olma
--    3. SetEntityCollision(ped, false) ile çarpışma kapatma
--
--  False positive koruması:
--    - Taşıma scriptleri (carry/piggyback) whitelist animasyonları
--    - Admin bypass (ace permission)
--    - Araç içindeyken kontrol yapılmaz
--    - Tek seferlik tespit yetmez, threshold sistemi
-- ============================================================

local MODULE_NAME = "player_attach_detect"

-- -------------------------------------------------------
--  Whitelist: Meşru taşıma animasyonları
--  Bu animasyonlar oynanıyorsa tespit yapılmaz
--  (carry script, hostage, fireman carry vb.)
-- -------------------------------------------------------
local CARRY_ANIMS = {
    -- Yaygın carry/taşıma scriptleri
    { dict = "missfinale_c2mcs_1",      anim = "fin_c2_mcs_1_camman"       },
    { dict = "nm",                       anim = "firemans_carry"            },
    { dict = "anim@gangops@hostage@",    anim = "fwd_walk_hostage"          },
    { dict = "anim@gangops@hostage@",    anim = "fwd_walk_hostage_taker"    },
    { dict = "anim@heists@box_carry@",   anim = "idle"                      },
    { dict = "amb@world_human_seat_wall@male@hands_by_side@base", anim = "base" },
    -- Piggyback / sırtına alma
    { dict = "anim@arena@celeb@flat@paired@no_props@", anim = "piggyback_b_player_a" },
    { dict = "anim@arena@celeb@flat@paired@no_props@", anim = "piggyback_b_player_b" },
    -- Kucaklama / taşıma
    { dict = "rcmpaparazzo_2",           anim = "yourfault_intro"           },
}

-- -------------------------------------------------------
--  Yardımcı: Oyuncu meşru bir taşıma animasyonu oynuyor mu?
-- -------------------------------------------------------
local function IsPlayingCarryAnim(ped)
    for _, a in ipairs(CARRY_ANIMS) do
        if IsEntityPlayingAnim(ped, a.dict, a.anim, 3) then
            return true
        end
    end
    return false
end

-- -------------------------------------------------------
--  Yardımcı: Ped başka bir oyuncu ped'ine attach mi?
--  Döndürür: isAttached, targetPed
-- -------------------------------------------------------
local function IsAttachedToPlayerPed(ped)
    if not IsEntityAttachedToAnyEntity(ped) then
        return false, nil
    end

    -- Attach edildiği entity'yi bul
    local pool = GetActivePlayers()
    for _, playerId in ipairs(pool) do
        if playerId ~= PlayerId() then
            local targetPed = GetPlayerPed(playerId)
            if targetPed and targetPed ~= 0 and DoesEntityExist(targetPed) then
                if IsEntityAttachedToEntity(ped, targetPed) then
                    return true, targetPed, GetPlayerServerId(playerId)
                end
            end
        end
    end

    return false, nil, nil
end

-- -------------------------------------------------------
--  Modül kayıt (ACModules döngüsü için — 5 saniyelik analiz)
-- -------------------------------------------------------
RegisterACModule(MODULE_NAME, function()
    -- Bu fonksiyon 5 saniyede bir çağrılır (client.lua ana döngüsü)
    -- Asıl tespit aşağıdaki ayrı thread'de yapılır
    -- Burası sadece modülün aktif olduğunu gösterir
end)

-- -------------------------------------------------------
--  Config değerlerini al
-- -------------------------------------------------------
local cfg = Config.PlayerAttachDetect or {}
local CHECK_INTERVAL     = cfg.CheckIntervalMs or 1000
local DETECTION_THRESHOLD = cfg.DetectionThreshold or 3
local COOLDOWN_MS        = cfg.CooldownMs or 60000

-- -------------------------------------------------------
--  Tespit state
-- -------------------------------------------------------
local detectionCount = 0
local lastReportTime = 0

-- -------------------------------------------------------
--  Ana tespit döngüsü
-- -------------------------------------------------------
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(CHECK_INTERVAL)

        local ped = PlayerPedId()

        -- Temel kontroller
        if not DoesEntityExist(ped) or IsEntityDead(ped) then
            goto continue
        end

        -- Araç içindeyken kontrol yapma
        if IsPedInAnyVehicle(ped, false) then
            detectionCount = 0
            goto continue
        end

        -- -----------------------------------------------
        --  Tespit 1: Başka bir oyuncuya attach + görünmez
        -- -----------------------------------------------
        local isAttached, targetPed, targetServerId = IsAttachedToPlayerPed(ped)

        if isAttached then
            local isInvisible    = not IsEntityVisible(ped)
            local noCollision    = not -- GTA V'de collision durumunu doğrudan
                                       -- sorgulayamıyoruz, ama görünmezlik
                                       -- + attach zaten yeterli imza
                                       false

            -- Meşru taşıma animasyonu kontrolü
            if IsPlayingCarryAnim(ped) then
                -- Carry script kullanılıyor, false positive
                detectionCount = 0
                goto continue
            end

            -- Görünmez + attach = kesin hile imzası
            if isInvisible then
                detectionCount = detectionCount + 2 -- Ağırlıklı artış
                local detail = string.format(
                    "Görünmez yapışma tespiti! Hedef ID: %s | Görünmez: EVET | Attach: EVET | Sayaç: %d/%d",
                    tostring(targetServerId or "?"),
                    detectionCount,
                    DETECTION_THRESHOLD
                )
                print(string.format("^1[AntiCheat:PlayerAttach] ^7%s", detail))

                if detectionCount >= DETECTION_THRESHOLD then
                    local now = GetGameTimer()
                    if (now - lastReportTime) > COOLDOWN_MS then
                        lastReportTime = now
                        detectionCount = 0
                        TriggerServerEvent("anticheat:playerAttachDetected", detail, targetServerId)
                    end
                end
                goto continue
            end

            -- Attach ama görünür = muhtemelen carry script, ama yine de say
            -- (carry animasyonu yoksa şüpheli)
            detectionCount = detectionCount + 1
            if detectionCount >= DETECTION_THRESHOLD then
                local now = GetGameTimer()
                if (now - lastReportTime) > COOLDOWN_MS then
                    lastReportTime = now
                    detectionCount = 0
                    local detail = string.format(
                        "Şüpheli yapışma! Hedef ID: %s | Görünmez: HAYIR | Animasyon: YOK | Sayaç: eşik aşıldı",
                        tostring(targetServerId or "?")
                    )
                    TriggerServerEvent("anticheat:playerAttachDetected", detail, targetServerId)
                end
            end
        else
            -- -----------------------------------------------
            --  Tespit 2: Görünmez + çarpışmasız (noclip benzeri)
            --  Attach olmasa bile görünmezlik şüpheli
            -- -----------------------------------------------
            local isInvisible = not IsEntityVisible(ped)

            if isInvisible then
                detectionCount = detectionCount + 1
                if detectionCount >= (DETECTION_THRESHOLD + 2) then
                    local now = GetGameTimer()
                    if (now - lastReportTime) > COOLDOWN_MS then
                        lastReportTime = now
                        detectionCount = 0
                        local detail = "Oyuncu görünmez durumda! (attach yok ama invisible)"
                        TriggerServerEvent("anticheat:playerAttachDetected", detail, nil)
                    end
                end
            else
                -- Temiz durum — sayacı yavaşça düşür
                if detectionCount > 0 then
                    detectionCount = detectionCount - 1
                end
            end
        end

        ::continue::
    end
end)
