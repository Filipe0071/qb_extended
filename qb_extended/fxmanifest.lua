fx_version "adamant"

game "gta5"

server_scripts {"server/*.lua", "common/modules/*.lua", "common/*.lua"}

client_scripts {"client/*.lua", "client/modules/*.lua", "common/modules/*.lua", "common/*.lua"}

files {"imports.lua", "html/js/wrapper.js"}

exports {"getSharedObject"}

server_exports {"getSharedObject"}
