-- main.lua
-- pigybug
local skynet = require "skynet"
local cluster = require "skynet.cluster"

local common = {
    { name = "d_account", key = "sdkid,pid", indexkey = "id" },
}

skynet.start(function()
    local log = skynet.uniqueservice("log")
    skynet.call(log, "lua", "start")
    
    local dbmgr = skynet.uniqueservice("dbmgr")
    skynet.call(dbmgr, "lua", "start", {}, {}, common)

    local logind = skynet.uniqueservice("logind")
    skynet.call(logind, 'lua', 'start')
    cluster.open("login")
end)
