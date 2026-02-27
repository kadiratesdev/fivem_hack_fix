fx_version 'cerulean'
game 'gta5'

author 'AntiCheat System'
description 'Modular FiveM AntiCheat - Bypass Script Detector'
version '1.9.0'

-- Shared config
shared_scripts {
    'config.lua',
}

-- Server-side scripts
server_scripts {
    'server/server.lua',
    'server/weapon_check_server.lua',  -- ox_inventory silah envanter kontrolü
    'server/ammo_check_server.lua',    -- Sınırsız mermi tespiti
    'server/aimbot_detect_server.lua',          -- Aimbot / Silent Aim tespiti
    'server/player_attach_detect_server.lua',   -- Görünmez yapışma tespiti
    'server/vehicle_spawn_detect_server.lua',   -- Yetkisiz araç spawn tespiti
    'server/vehicle_mod_detect_server.lua',     -- Yetkisiz araç tuning tespiti
    'server/teleport_detect_server.lua',        -- Teleport (TP) + Freecam tespiti
    'server/speedhack_detect_server.lua',       -- Speedhack tespiti
}

-- Client-side scripts
client_scripts {
    'client/loader.lua',
    'client/client.lua',
    'client/weapon_check_client.lua',  -- Silah zorla kaldırma handler
    'bypassscripts/*.lua',
}

-- ox_inventory dependency
dependency 'ox_inventory'

lua54 'yes'
