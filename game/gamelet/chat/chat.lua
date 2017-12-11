-- chat.lua
-- a simple test chat game
local socket = require 'skynet.socket'
require 'skynet.netpack'
local table = require 'table'

local room

function init(source)
    room = source
    LOG_INFO('game chat associated to room %d', room)
end

function exit(...)
end

local function send_msg(fd, resp)
    local pack = string.pack('>I2', #resp) .. resp
    socket.write(fd, pack)
end

-- when user enter this game
function accept.enter(user)
    LOG_INFO('user %d enter chat', user.userid)
    send_msg(user.fd, 'welcome to chat game: ' .. tostring(user.userid))
end

function accept.leave(user)
    LOG_INFO('user %d leave chat', user.userid)
end

-- recv client game message
function accept.play(user, detail)
    LOG_INFO('user %d play chat: %s', user.userid, detail)
    local resp = 'hello:' .. detail
    send_msg(user.fd, resp)
end

