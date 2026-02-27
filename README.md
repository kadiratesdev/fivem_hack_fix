# FiveM Modüler AntiCheat

Modüler yapıda FiveM anti-cheat sistemi. `bypassscripts/` klasörüne yeni `.lua` dosyası ekleyerek kolayca genişletilebilir.

## Klasör Yapısı

```
fivem-anticheat/
├── fxmanifest.lua          # Resource manifest
├── config.lua              # Genel ayarlar
├── server/
│   └── server.lua          # Ban/kick/log işlemleri
├── client/
│   ├── loader.lua          # Modül kayıt sistemi
│   └── client.lua          # Ana kontrol döngüsü
└── bypassscripts/
    ├── hulkfix.lua         # HulkFix bypass tespiti
    ├── noclip_detect.lua   # NoClip tespiti
    └── (yeni modüller...)
```

## Kurulum

1. `fivem-anticheat` klasörünü sunucunuzun `resources/` dizinine kopyalayın.
2. `server.cfg` dosyanıza ekleyin:
   ```
   ensure fivem-anticheat
   ```
3. `config.lua` dosyasını düzenleyin.

## Yeni Modül Ekleme

`bypassscripts/` altına yeni bir `.lua` dosyası oluşturun:

```lua
-- bypassscripts/benim_modulüm.lua

local function CheckBenimModulum()
    -- Tespit mantığınız buraya
    if _G["SuspiciousVar"] ~= nil then
        ReportDetection("benim_modulüm", "Şüpheli değişken bulundu")
    end
end

-- Modülü kaydet
RegisterACModule("benim_modulüm", CheckBenimModulum)
```

Ardından `config.lua` içinde aktif edin:

```lua
Config.Modules = {
    hulkfix        = true,
    noclip_detect  = true,
    benim_modulüm  = true,  -- yeni modül
}
```

## Olaylar (Events)

| Event | Yön | Açıklama |
|-------|-----|----------|
| `anticheat:detected` | Client → Server | Tespit bildirimi |
| `anticheat:notify` | Server → Client | UI bildirimi |

## Admin Komutları

| Komut | Açıklama |
|-------|----------|
| `/acban <id> <sebep>` | Oyuncuyu banla (konsol veya admin) |

## Config Seçenekleri

| Ayar | Varsayılan | Açıklama |
|------|-----------|----------|
| `Config.Action` | `"ban"` | `"ban"`, `"kick"`, `"warn"` |
| `Config.BanDuration` | `0` | Dakika (0 = kalıcı) |
| `Config.LogWebhook` | `""` | Discord webhook URL |
| `Config.Modules` | `{hulkfix=true}` | Aktif modüller |
