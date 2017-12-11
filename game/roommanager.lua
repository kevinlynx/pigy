-- roommanager.lua
-- manage room list 
local skynet = require 'skynet'
local snax = require 'skynet.snax'
require 'skynet.manager'
local table = require 'table'

local gamelets = {}
local room_map = {} -- room_id: room
local user2rooms = {}
local username_map = {} -- usernmae: user

local command = {}

function command.start()
    local fn, err = loadfile(skynet.getenv('gamelet'))
    if not fn then 
        error('load gamelet config failed:' .. err)
    end
    local conf = fn()
    for _, g in ipairs(conf) do
        gamelets[g.id] = g
        LOG_INFO('register game %d:%s', g.id, g.name)
    end
end

-- called by hall
function command.get()
    --[[
        {gid: [{id: room_id, sname: server_name}]}
    --]]
    -- TODO: this IP can be used with a gate server ?
    local server = {ip = skynet.getenv('ap_ip'), port = skynet.getenv('port')}
    local game_infos = {}
    for id, _ in pairs(gamelets) do game_infos[id] = {} end
    for _, room in pairs(room_map) do
        local info = skynet.call(room, 'lua', 'get_info')
        table.insert(game_infos[info.gid], info)
    end
    return {game_infos = game_infos, server = server}
end

local function user_checkin(user)
    LOG_INFO('user checkin server: %d:%s:%s', user.userid, user.username, user.secret)
    username_map[user.username] = user
end

command.user_checkin = user_checkin

function command.get_user(username)
    return username_map[username]
end

local function new_room(rid, gid)
    local room = skynet.newservice('room')
    skynet.call(room, 'lua', 'start', rid, {id = gid, name = gamelets[gid].name})
    room_map[rid] = room
    return true
end

-- called by hall
function command.create_room(id, user, rid)
    user_checkin(user) 
    new_room(rid, id)
    LOG_INFO('create a new room for game %d by user %d', id, user.userid)
    return rid
end

-- called by hall
function command.destroy_room(id, user)
    local room = room_map[id]
    if not room then
        return 404
    end
    LOG_INFO('destroy a room %d by user %d', id, user.userid)
    local f = skynet.call(room, 'lua', 'destroyable')
    if not f then
        return 403
    end
    room_map[id] = nil
    skynet.send(room, 'lua', 'destroy')
    return 200
end

-- called by hall
function command.select_room(id, user)
    if room_map[id] == nil then
        return 404
    end
    user_checkin(user) 
    return 200
end

-- called by hall, usually recover from db
function command.ensure_room(row)
    local id = row.id
    if room_map[id] ~= nil then
        return true
    end
    new_room(row.id, row.game)
    LOG_INFO('ensure room %d for game %d', id, row.game)
    return true
end

-- called by client
function command.enter_room(user, rid)
    local room = room_map[rid]
    if not room then
        LOG_WARNING('not found room:%d', rid)
        return
    end
    user2rooms[user.userid] = rid
    skynet.call(room, 'lua', 'user_enter', user)
end

-- called by hall
function command.leave_room(user)
    local rid = user2rooms[user.userid]
    if not rid then
        LOG_WARNING('not found room for user %d', user.userid)
        return 404
    end
    LOG_INFO('user leave room, uid %d, rid %d', user.userid, rid)
    local room = room_map[rid]
    assert(room)
    skynet.call(room, 'lua', 'user_leave', user)
    user2rooms[user.userid] = nil
    username_map[user.username] = nil
    return 200
end

function command.play_game(user, detail)
    local rid = user2rooms[user.userid]
    local room = room_map[rid]
    skynet.send(room, 'lua', 'play_game', user, detail)
end

skynet.start(function() 
    skynet.dispatch("lua", function(session, address, cmd, ...)
        local f = command[cmd]
        if f then
            skynet.ret(skynet.pack(f(...)))
        else
            error(string.format("Unknown command %s", tostring(cmd)))
        end
    end)
    skynet.register('roommanager')
end)

