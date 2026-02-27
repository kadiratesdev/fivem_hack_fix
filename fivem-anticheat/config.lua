-- ============================================================
--  AntiCheat Config
-- ============================================================

Config = {}

-- Ban mesajı
Config.BanMessage = "^1[AntiCheat] ^7Sunucudan banlandınız.\nSebep: %s"

-- Ban süresi (dakika, 0 = kalıcı)
Config.BanDuration = 0

-- Log kanalı (Discord webhook veya print)
Config.LogWebhook = "" -- Discord webhook URL buraya

-- Tespit edilen bypass scriptleri için aksiyon
-- "ban"  = direkt ban
-- "kick" = kick + log
-- "warn" = sadece log
Config.Action = "ban"

-- Hangi bypass modülleri aktif?
Config.Modules = {
    hulkfix   = true,
    -- yeni modüller buraya eklenebilir
    -- mymod = true,
}

-- Sunucu adı (log mesajlarında görünür)
Config.ServerName = "MyFiveM Server"
