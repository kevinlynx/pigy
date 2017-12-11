-- c_game.lua
-- connect to game server
local socket = require "client.socket"
local crypt = require "client.crypt"
local util = require 'client_util'
local protobuf = require 'protobuf'

protobuf.register_file("protocol/netmsg.pb")
protobuf.register_file("protocol/game.pb")

local fd

local c_game = {}

function c_game.handshake(ip, port, secret, username)
    fd = assert(socket.connect(ip, port))
    util.send_package(fd, crypt.base64encode(secret) .. '@' .. username)
    ok, msg = util.gs_recv_response(util.readpackage(fd))
    return ok, msg
end

function c_game.enter_game(rid)
    util.gs_send_request(fd, util.encode("game.EnterRoom", {rid = rid}))
end

function c_game.send_game_msg(data)
    util.gs_send_request(fd, util.encode("game.PlayGame", {detail = data}))
end

function c_game.recv_game_msg()
    ok, msg = util.gs_recv_response(util.readpackage(fd))
    assert(ok)
    return msg
end

function c_game.shutdown()
    socket.close(fd)
end

return c_game

