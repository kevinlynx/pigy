-- main.lua
local skynet = require "skynet"
local snax = require "skynet.snax"
local cluster = require "skynet.cluster"

skynet.start(function()
    local log = skynet.uniqueservice("log")
    skynet.call(log, "lua", "start")
    
    skynet.newservice("debug_console", tonumber(skynet.getenv("debug_port")))

    local gm = skynet.uniqueservice('roommanager')
    skynet.call(gm, 'lua', 'start')

    local gate = skynet.uniqueservice("watchdog")
    skynet.call(gate, "lua", "start" , {
        port = tonumber(skynet.getenv("port")) or 8888,
        maxclient = tonumber(skynet.getenv("maxclient")) or 1024,
        nodelay = true,
    })
    cluster.open(NODE_NAME)
end)
