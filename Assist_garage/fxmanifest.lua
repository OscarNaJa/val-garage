shared_script "@bt_defender/module/shared.lua"


fx_version 'cerulean'

game 'gta5'

description 'garage'

version '1.0.0'
lua54 'yes'

files {
	'ui/ui.html',
	'ui/style.css',
	'ui/main.js',
	'ui/img/*.png',
	'ui/*.ttf',
	'ui/sound/*.mp3',
	'ui/sound/*.ogg',
	'ui/iconify-icon.min.js'
}

ui_page {
	'ui/ui.html'
}

server_scripts {
	'@mysql-async/lib/MySQL.lua',
	'config.lua',
	-- 'config.lua',
	'config.poundDetail.lua',
	'config.garageDetail.lua',
	'config.depositvehicle.lua',
	'server/server.lua'
}

client_scripts {
	'@es_extended/locale.lua',	
	'config.lua',	
	'config.poundDetail.lua',
	'config.garageDetail.lua',
	'config.depositvehicle.lua',
	'client/client.lua',
	'client/add.lua',
}

dependencies {
	'es_extended',
	'DTT_3d',
	-- 'esx_vehicleshop'
}