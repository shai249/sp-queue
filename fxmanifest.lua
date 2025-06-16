fx_version 'cerulean'
game 'gta5'

author 'Sh1k0P1k0'
description 'Sh1k0P1k0\'s Queue System'
version '1.0.0'

server_scripts {
    'config.lua', 'lang.lua', 'src/utils/Logger.lua', 'src/models/Player.lua',
    'src/models/Queue.lua', 'src/services/DiscordService.lua',
    'src/services/WebhookService.lua', 'src/services/ValidationService.lua',
    'src/views/CardView.lua', 'src/controllers/QueueController.lua',
    'src/controllers/CommandController.lua', 'src/QueueManager.lua'
}

files {'presentCard.json'}

lua54 'yes'
