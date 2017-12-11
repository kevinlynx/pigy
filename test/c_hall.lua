-- c_hall.lua
-- client connect to hall server
local socket = require "client.socket"
local crypt = require "client.crypt"
local util = require 'client_util'
local protobuf = require 'protobuf'

protobuf.register_file("protocol/netmsg.pb")
protobuf.register_file("protocol/hall.pb")

local session = 0
local fd
local ls

local c_hall = {}

-- not used with msgserver0
local function next_sid()
    return session
end

function c_hall.connect(login_state, index)
    ls = login_state
    local vec = string.split(ls.server, ':')
    local ip, port = vec[1], tonumber(vec[2])
    fd = assert(socket.connect(ip, port))

    local handshake = ls.username
    local hmac = crypt.hmac64(crypt.hashkey(handshake), ls.secret)
    util.send_package(fd, handshake .. ":" .. crypt.base64encode(hmac))
    local resp = util.readpackage(fd)
    print(resp)
    return resp
end

function c_hall.get_user()
    util.hs_send_request(fd, util.encode("hall.GetUserInfo", {}), next_sid())
    local ok, msg, sess = util.hs_recv_response(util.readpackage(fd))
    assert(sess == session)
    msg = util.decode(msg)
    local submsg = protobuf.decode("hall.GetUserInfoResponse", msg.payload)
    print('get user response')
    return submsg
end

function c_hall.get_game_list()
    util.hs_send_request(fd, util.encode("hall.GetGameList", {}), next_sid())
    local ok, msg, sess = util.hs_recv_response(util.readpackage(fd))
    assert(sess == session)
    msg = util.decode(msg)
    local submsg = protobuf.decode("hall.GetGameListResponse", msg.payload)
    return submsg
end

function c_hall.create_room(id)
    util.hs_send_request(fd, util.encode("hall.CreateRoom", {id = id}), next_sid())
    ok, msg, sess = util.hs_recv_response(util.readpackage(fd))
    assert(sess == session)
    msg = util.decode(msg)
    submsg = protobuf.decode("hall.CreateRoomResponse", msg.payload)
    return submsg.rid, submsg.server
end

function c_hall.destroy_room(id)
    util.hs_send_request(fd, util.encode("hall.DestroyRoom", {id = id}), next_sid())
    ok, msg, sess = util.hs_recv_response(util.readpackage(fd))
    assert(sess == session)
    msg = util.decode(msg)
    submsg = protobuf.decode("hall.DestroyRoomResponse", msg.payload)
    return submsg.code
end

function c_hall.leave_room()
    util.hs_send_request(fd, util.encode("hall.LeaveRoom", {}), next_sid())
    ok, msg, sess = util.hs_recv_response(util.readpackage(fd))
    assert(sess == session)
    msg = util.decode(msg)
    submsg = protobuf.decode("hall.LeaveRoomResponse", msg.payload)
    return submsg.code
end

function c_hall.select_room(rid, sname)
    util.hs_send_request(fd, util.encode("hall.SelectRoom", {rid = rid, sname = sname}), next_sid())
    ok, msg, sess = util.hs_recv_response(util.readpackage(fd))
    assert(sess == session)
    msg = util.decode(msg)
    submsg = protobuf.decode("hall.SelectRoomResponse", msg.payload)
    print(string.format('select room resp: %d', submsg.code))
    assert(submsg.code == 200)
    return submsg.server
end

function c_hall.reconn_room()
    util.hs_send_request(fd, util.encode("hall.ReconnRoom", {}), next_sid())
    ok, msg, sess = util.hs_recv_response(util.readpackage(fd))
    assert(sess == session)
    msg = util.decode(msg)
    submsg = protobuf.decode("hall.ReconnRoomResponse", msg.payload)
    print(string.format('reconn room resp: %d: %d@%s:%d', submsg.code, submsg.rid, submsg.server.ip, 
        submsg.server.port))
    assert(submsg.code == 200)
    return submsg.server, submsg.rid
end

function c_hall.shutdown()
    if fd ~= nil then
        socket.close(fd)
    end
end

return c_hall
