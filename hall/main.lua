-- main.lua
local skynet = require "skynet"
local snax = require "skynet.snax"
local cluster = require "skynet.cluster"
local protobuf = require 'protobuf'

local common = {
    { name = "d_room", key = "id", indexkey = "id" },
}

local user = {
    { name = 'd_user', key = 'uid'},
}

skynet.start(function()
    local log = skynet.uniqueservice("log")
    skynet.call(log, "lua", "start")
    
    skynet.newservice("debug_console", tonumber(skynet.getenv("debug_port")))

    local dbmgr = skynet.uniqueservice("dbmgr")
    skynet.call(dbmgr, "lua", "start", {}, user, common)

    skynet.call(skynet.uniqueservice('roomproxy'), 'lua', 'start')

    local gate = skynet.uniqueservice("gated")
    skynet.call(gate, "lua", "open" , {
        port = tonumber(skynet.getenv("port")) or 8888,
        maxclient = tonumber(skynet.getenv("maxclient")) or 1024,
        servername = NODE_NAME,
    })

    cluster.open(NODE_NAME)
end)
