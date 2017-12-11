-- client_util.lua
local socket = require "client.socket"
local crypt = require "client.crypt"
local protobuf = require 'protobuf'
local message_map = require 'message_map'

message_map.mapping('hall', 'game')

local util = {}

local function unpack_line(text)
    local from = text:find("\n", 1, true)
    if from then
        return text:sub(1, from-1), text:sub(from+1)
    end
    return nil, text
end

local last = ""

local function unpack_f(f)
    local function try_recv(fd, last)
        local result
        result, last = f(last)
        if result then
            return result, last
        end
        local r = socket.recv(fd)
        if not r then
            return nil, last
        end
        if r == "" then
            error "Server closed"
        end
        return f(last .. r)
    end

    return function(fd)
        while true do
            local result
            result, last = try_recv(fd, last)
            if result then
                return result
            end
            socket.usleep(100)
        end
    end
end

util.readline = unpack_f(unpack_line)

function util.writeline(fd, text)
    socket.send(fd, text .. "\n")
end

function util.encode(name, data)
    local payload = protobuf.encode(name, data)
    local id = message_map.get_id(name)
    local netmsg = { id = id, payload = payload }
    local pack = protobuf.encode("netmsg.NetMsg", netmsg)
    return pack
end

function util.decode(data)
    local netmsg = protobuf.decode("netmsg.NetMsg", data)
    if netmsg.code ~= 0 then
        error('decode msg failed:' .. netmsg.payload)
    end
    return netmsg
end

local function unpack_package(text)
    local size = #text
    if size < 2 then
        return nil, text
    end
    local s = text:byte(1) * 256 + text:byte(2)
    if size < s+2 then
        return nil, text
    end

    return text:sub(3,2+s), text:sub(3+s)
end

function util.send_package(fd, pack)
    local package = string.pack(">s2", pack)
    socket.send(fd, package)
end

util.readpackage = unpack_f(unpack_package)

function util.hs_send_request(fd, v, session)
    local size = #v 
    local package = string.pack(">I2", size)..v
    socket.send(fd, package)
    return v, session
end

function util.hs_recv_response(v)
    local size = #v
    local content, ok = string.unpack("c"..tostring(size), v)
    return ok ~=0 , content, 0
end

function util.gs_send_request(fd, v)
    local size = #v
    local package = string.pack(">I2", size)..v
    socket.send(fd, package)
    return v
end

function util.gs_recv_response(v)
    local size = #v
    local content, ok = string.unpack("c"..tostring(size), v)
    return ok ~=0 , content
end

function util.write_login_state(username, secret, index)
    local fp = io.open('logins', 'w')
    local s = string.format('%s:%d:%s', username, index, crypt.base64encode(secret))
    fp:write(s)
    fp:close()
end

local function split(s, delim)
    local split = {}
    local pattern = "[^" .. delim .. "]+"
    string.gsub(s, pattern, function(v) table.insert(split, v) end)
    return split
end

function util.read_login_state()
    local fp = io.open('logins')
    if not fp then
        return nil
    end
    local s = fp:read('*a')
    local sec = split(s, ':')
    return {username = sec[1], index = tonumber(sec[2]), secret = crypt.base64decode(sec[3])}
end

return util

