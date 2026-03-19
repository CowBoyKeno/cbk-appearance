fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'cbk-appearance'
author 'CowBoyKeno'
description 'Standalone production-grade appearance creator/editor'
version '1.7.0'

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/app.js',
    'web/styles.css'
}

shared_scripts {
    'shared/config.lua',
    'shared/schema.lua'
}

client_scripts {
    'client/utils.lua',
    'client/state.lua',
    'client/appearance.lua',
    'client/camera.lua',
    'client/nui.lua',
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/ratelimit.lua',
    'server/validate.lua',
    'server/persistence.lua',
    'server/main.lua'
}

dependencies {
    '/onesync'
}
