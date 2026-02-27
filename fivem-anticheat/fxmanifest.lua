fx_version 'cerulean'
game 'gta5'

author 'AntiCheat System'
description 'Modular FiveM AntiCheat - Bypass Script Detector'
version '1.0.0'

-- Shared config
shared_scripts {
    'config.lua',
}

-- Server-side scripts
server_scripts {
    'server/server.lua',
}

-- Client-side scripts
client_scripts {
    'client/loader.lua',
    'client/client.lua',
    'bypassscripts/*.lua',
}

lua54 'yes'
