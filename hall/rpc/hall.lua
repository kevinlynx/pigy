-- hall.lua
local skynet = require 'skynet'
local snax = require "skynet.snax"
local protobuf = require "protobuf"
local table = require 'table'
local message = require 'message'

local roomdc

function init(...)
    protobuf.register_file("./protocol/netmsg.pb")
    protobuf.register_file("./protocol/hall.pb")
    roomdc = snax.uniqueservice('roomdc')
end

function exit(...)
end

function response.GetGameList(data)
    local _ = pb_decode(data)
    local game_infos = skynet.call('roomproxy', 'lua', 'get')
    local games = {}
    for id, rooms in pairs(game_infos) do
        local room_infos = {}   
        for _, room in ipairs(rooms) do
            table.insert(room_infos, {gid = id, sname = room.sname, rid = room.id})
        end
        local game = {gid = id, rooms = room_infos}
        table.insert(games, game)
    end
    return message.pack("hall.GetGameListResponse", {games = games})
end

function response.CreateRoom(data, user)
    local args = pb_decode(data)
    local rid = roomdc.req.get_nextid()
    local ok, ret, sname = skynet.call('roomproxy', 'lua', 'create_room', args.id, user, rid)
    if not ok then -- room id will have a gap
        error(ret)
    end
    local row = {id = rid, creator = user.userid, game = args.id, server = sname}
    local ok = roomdc.req.add(row)
    if not ok then
        LOG_ERROR('add to roomdc failed, game %d, uid %d', args.id, user.userid)
        error(ok)
    end
    skynet.call(user.service, 'lua', 'set_room', rid, sname)
    return message.pack('hall.CreateRoomResponse', ret)
end

function response.DestroyRoom(data, user)
    local args = pb_decode(data)
    local code = skynet.call('roomproxy', 'lua', 'destroy_room', args.id, user)
    if code == 200 then
        roomdc.req.delete({id = args.id})
    end
    return message.pack('hall.DestroyRoomResponse', {code = code})
end

function response.SelectRoom(data, user)
    local args = pb_decode(data)
    local code, sinfo = skynet.call('roomproxy', 'lua', 'select_room', args.rid, args.sname, user)
    if code == 200 then
        skynet.call(user.service, 'lua', 'set_room', args.rid, args.sname)
    end
    return message.pack('hall.SelectRoomResponse', {code = code, server = sinfo})
end

function response.ReconnRoom(data, user)
    local room = skynet.call(user.service, 'lua', 'get_room')
    if room then
        local code, sinfo = skynet.call('roomproxy', 'lua', 'select_room', room.rid, room.sname, user)
        return message.pack('hall.ReconnRoomResponse', {code = code, server = sinfo, rid = room.rid})
    end
    return message.pack('hall.ReconnRoomResponse', {code = 404})
end

function response.LeaveRoom(data, user)
    LOG_DEBUG('rpc recv LeaveRoom from user %d', user.userid)
    local args = pb_decode(data)
    local code = skynet.call('roomproxy', 'lua', 'leave_room', user)
    if code == 200 then
        skynet.call(user.service, 'lua', 'set_room', 0, '')
    end
    return message.pack('hall.LeaveRoomResponse', {code = code})
end

function response.GetUserInfo(data, user)
    local room = user.room
    print('get user info ')
    local result = {}
    if room then
        result.room = room
    end
    return message.pack('hall.GetUserInfoResponse', result)
end

