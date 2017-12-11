-- rpc/game.lua
local skynet = require 'skynet'
local protobuf = require "protobuf"
local message = require 'message'

function init(...)
    protobuf.register_file("./protocol/netmsg.pb")
    protobuf.register_file("./protocol/game.pb")
end

function exit(...)
end

function accept.EnterRoom(data, user)
    LOG_DEBUG('rpc recv EnterRoom from user %d', user.userid)
    local args = pb_decode(data)
    local rid = args.rid
    skynet.send('roommanager', 'lua', 'enter_room', user, rid)
end

function accept.PlayGame(data, user)
    local args = pb_decode(data)
    skynet.send('roommanager', 'lua', 'play_game', user, args.detail)
end

