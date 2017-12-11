-- c_login.lua
-- client login
local socket = require "client.socket"
local crypt = require "client.crypt"
local util = require 'client_util'

local ip, port
local c_login = {}

local function encode_token(pid, server, sdkid)
    local password = ''
    local token = crypt.base64encode(pid .. password)
    return string.format("%s:%s:%s:%d", server, token, sdkid, pid)
end

function c_login.set_addr(ip_, port_)
    ip = ip_
    port = port_
end

function c_login.register(sdkid, pid, password)
    local fd = assert(socket.connect(ip, port))
    util.writeline(fd, 'LS register')
    util.writeline(fd, string.format('%d:%s:%s', sdkid, pid, password or ''))
    print(util.readline(fd))
    socket.close(fd)
end

function c_login.bind(sdkid1, pid1, sdkid2, pid2)
    local fd = assert(socket.connect(ip, port))
    util.writeline(fd, 'LS bind')
    util.writeline(fd, string.format('%d:%s:%d:%s', sdkid1, pid1, sdkid2, pid2))
    print(util.readline(fd))
    socket.close(fd)
end

function c_login.login(pid, server, sdkid)
    local fd = assert(socket.connect(ip, port))
    util.writeline(fd, 'LS login')
    local challenge = crypt.base64decode(util.readline(fd))
    local clientkey = crypt.randomkey()
    util.writeline(fd, crypt.base64encode(crypt.dhexchange(clientkey)))
    local secret = crypt.dhsecret(crypt.base64decode(util.readline(fd)), clientkey)
    local hmac = crypt.hmac64(challenge, secret)
    util.writeline(fd, crypt.base64encode(hmac))
    local etoken = crypt.desencode(secret, encode_token(pid, server, sdkid))
    local b = crypt.base64encode(etoken)
    util.writeline(fd, crypt.base64encode(etoken))

    local result = util.readline(fd)
    local code = tonumber(string.sub(result, 1, 3))
    socket.close(fd)
    if code ~= 200 then
        return code
    end
    local pack = crypt.base64decode(string.sub(result, 5))
    local vec = string.split(pack, ' ')
    local username, server = vec[1], vec[2]
    return code, {username = username, server = server, hmac = hmac, secret = secret}
end

return c_login

