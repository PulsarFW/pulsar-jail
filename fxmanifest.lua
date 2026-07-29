fx_version 'cerulean'
game 'gta5'

name 'Pulsar Jail'
description 'Prison sentencing with cell zones and time-served auto-release'
author 'Artmines - maintained for Pulsar Framework'
url 'https://pulsarframe.work'
version 'v1.0.0'

version_check 'yes'
github 'https://github.com/PulsarFW/pulsar_jail'

client_script '@pulsar_core/components/cl_error.lua'
shared_script '@pulsar_core/core/sh_pulsar.lua'
client_script '@pulsar_pwnzor/client/check.lua'

server_scripts({
	'server/**/*.lua',
})

shared_scripts({
	'config.lua',
})

client_scripts({
	'client/**/*.lua',
})

lua54 'yes'