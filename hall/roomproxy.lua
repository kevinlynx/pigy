-- roomproxy.lua
-- track all room in all game servers
local skynet = require 'skynet'
local snax = require "skynet.snax"
require 'skynet.manager'
local cluster = require 'skynet.cluster'

local game_infos = {} -- game_id: rooms, auto updated from all game servers
local gamelets = {} -- game_id: [server_name], auto updated from game servers
local server_infos = {} -- auto updated
local room2servers = {} -- auto updated
local command = {}

local function update_local(sname, pack)
    local games = pack.game_infos
    local server = pack.server
    server_infos[sname] = server
    for id, rooms in pairs(games) do
        if not game_infos[id] then game_infos[id] = {} end
        if not gamelets[id] then gamelets[id] = {} end
        table.insert(gamelets[id], sname)
        for _, room in ipairs(rooms) do
            room.sname = sname
            table.insert(game_infos[id], room)
            room2servers[room.id] = sname
        end
    end
end

local function clear() 
    game_infos = {}
    gamelets = {}
    room2servers = {}
end

local function do_update(servers)
    clear()
    for _, s in ipairs(servers) do
        local ok, pack = pcall(cluster.call, s, 'roommanager', 'get')
        if not ok then
            LOG_WARNING('cluster.call game server gamelist [%s] failed', s)
        else
            update_local(s, pack)
        end
    end
end

local function ensure_rooms()
    local roomdc = snax.uniqueservice('roomdc')   
    for _, row in pairs(roomdc.req.get_all()) do
        local server = row.server
        local ok, _ = pcall(cluster.call, server, 'roommanager', 'ensure_room', row)
        if not ok then
            LOG_WARNING('ensure room on server failed, rid %d, server %s', row.id, server)
        end
    end
end

local function update(servers)
    local tick = 0
    while true do
        if tick % 3 == 0 then -- target-based
            ensure_rooms()
        end
        do_update(servers)  
        tick = tick + 1
        skynet.sleep(500) -- 5s
    end
end

function command.start()
    local servers = string.split(skynet.getenv('gameservers'), ';')
    skynet.fork(update, servers)
end

function command.get()
    return game_infos
end

function command.create_room(id, user, rid)
    -- NOTE: gamelets will not be cleard in `update' ?
    local snames = gamelets[id] 
    if not snames then
        return nil, 'no server found'
    end
    local idx = 1 + math.random(65535) % #snames
    local name = snames[idx]
    local ok, ret = pcall(cluster.call, name, 'roommanager', 'create_room', id, user, rid)
    if not ok then
        return nil, string.format('call gameserver failed: %s', ret)
    end
    local sinfo = server_infos[name]
    return true, {server = sinfo, rid = ret}, name
end

function command.destroy_room(id, user)
    local sname = room2servers[id]
    if not sname then
        LOG_WARNING('not found room assocaited server %d', id)
        return 404
    end
    -- TODO: load from gameserver or from db/cache ?
    local roomdc = snax.uniqueservice('roomdc')   
    local room_r = roomdc.req.get(id)
    if not room_r then
        LOG_WARNING('not found room record from db/cache for %d', id)
        return 404
    end
    if room_r.creator ~= user.userid then
        LOG_WARNING('only room creator can destroy room, rid %d, uid %d, cid %d',
            id, user.userid, room_r.creator)
        return 403
    end
    local ok, code = pcall(cluster.call, sname, 'roommanager', 'destroy_room', id, user)
    LOG_INFO('destroy room on game server code %d, rid %d', code, id)
    return code
end

-- TODO: only pass `rid' here ?
function command.select_room(rid, sname, user)
    if server_infos[sname] == nil then
        LOG_WARNING('select room failed: not found gs [%s]', sname)
        return 404
    end
    local ok, ret = pcall(cluster.call, sname, 'roommanager', 'select_room', rid, user)
    if not ok then
        return 500
    end
    if ret ~= 200 then
        LOG_WARNING('room select failed on game server [%s] by rid %d, code %d', sname, rid, ret)
        return ret
    end
    local sinfo = server_infos[sname]
    return 200, sinfo
end

function command.leave_room(user)
    local room = skynet.call(user.service, 'lua', 'get_room')
    local rid = room.rid
    local sname = room2servers[rid]
    if not sname then
        LOG_WARNING('not found room assocaited server %d', rid)
        return 404
    end
    local ok, ret = pcall(cluster.call, sname, 'roommanager', 'leave_room', user)
    return ret
end

skynet.start(function() 
    math.randomseed(os.time())
    skynet.dispatch("lua", function(session, address, cmd, ...)
        local f = command[cmd]
        if f then
            skynet.ret(skynet.pack(f(...)))
        else
            error(string.format("Unknown command %s", tostring(cmd)))
        end
    end)
    skynet.register('roomproxy')
end)

