-- agent.lua
local skynet = require "skynet"
local message = require 'message'
local protobuf = require 'protobuf'
local socketdriver = require 'skynet.socketdriver'
local netpack = require 'skynet.netpack'
local crypt = require 'skynet.crypt'

local client_fd
local WATCHDOG
local user
local handshake

local CMD = {}

local function unpack_message(msg, sz)
    if handshake then
        return message.unpack(msg, sz)
    end
    handshake = true
    local data = skynet.tostring(msg, sz)   
    local secret, username = data:match "([^@]*)@(.*)"
    return {secret = secret, username = username}, true
end

local function auth(username, secret)
    local u
    if not username or not secret then
        err = '400 Bad Request'
    else
        secret = crypt.base64decode(secret)
        u = skynet.call('roommanager', 'lua', 'get_user', username)
        if not u then
            err = '404 User Not Found'
        elseif u.secret ~= secret then
            err = '401 Unauthorized'
        end
    end
    if err then
        socketdriver.send(client_fd, netpack.pack(err))
        skynet.call(WATCHDOG, 'lua', 'close', client_fd)
        return
    end
    user = u
    user.fd = client_fd
    socketdriver.send(client_fd, netpack.pack('200 OK'))
    LOG_INFO('user [%s:%d] handshake success', user.username, user.userid)
end

skynet.register_protocol {
    name = "client",
    id = skynet.PTYPE_CLIENT,
    unpack = unpack_message,
    -- NOTE: skynet will dispatch in more than 1 coroutine ?
    dispatch = function (_, _, netmsg, t)
        if t then
            return auth(netmsg.username, netmsg.secret)
        end
        message.dispatch_game(netmsg, user)
    end
}

function CMD.start(conf)
    local fd = conf.client
    local gate = conf.gate
    WATCHDOG = conf.watchdog
    client_fd = fd
    skynet.call(gate, "lua", "forward", fd)
end

function CMD.disconnect()
    -- todo: do something before exit
    skynet.exit()
end

skynet.start(function()
    message.mapping('game')
    skynet.dispatch("lua", function(_,_, command, ...)
        local f = CMD[command]
        skynet.ret(skynet.pack(f(...)))
    end)
    protobuf.register_file("./protocol/netmsg.pb")
end)
