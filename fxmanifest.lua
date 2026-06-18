fx_version 'cerulean'
game 'gta5'

name "tuff-nitro"
description "Tuff Advanced Nitrous & Purge v2"
author "Tuff Scriptrs "
version "2.1.9"

shared_scripts {
    '@ox_lib/init.lua',
    'config/*.lua'
}

client_scripts {
    'framework/client.lua',
    'client/*.lua'
}

server_scripts {
    'framework/server.lua',
    'framework/server_webhook.lua',
    'server/*.lua'
}

files {
    -- UI Files
    'ui/index.html',
    'ui/assets/*',
    'ui/*',
    'datas.json',
    -- Audio Files
    'data/antilag_sounds_tuff.dat54.rel',
    'audiodirectory/*.awc',
    -- Bottle Props
    'stream/tuff_bottleprops/*.ytyp',
    'stream/tuff_bottleprops/*.ydr',
    -- Exhaust Props
    'stream/tuff_exhaustprops/*.ytyp',
    'stream/tuff_exhaustprops/*.ydr',
    -- Exhaust and Nitrous Props
    'stream/exhaust/*.ypt',
    'stream/nitrous/*.ypt'
}

escrow_ignore {
    -- Main Config File
    'config/*.lua',
    -- Framework Files
    'framework/*.lua',
    -- Server Files
    'server/database.lua',
    'server/config.lua'
}

dependency 'ox_lib'
ui_page 'ui/index.html'

data_file 'AUDIO_WAVEPACK' 'audiodirectory'
data_file 'AUDIO_SOUNDDATA' 'data/antilag_sounds_tuff.dat'

data_file 'DLC_ITYP_REQUEST' 'stream/tuff_bottleprops/*.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/tuff_exhaustprops/*.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/exhaust/*.ypt'
data_file 'DLC_ITYP_REQUEST' 'stream/nitrous/*.ypt'

lua54 'yes'

dependency '/assetpacks'