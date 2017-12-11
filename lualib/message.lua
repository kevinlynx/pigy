-- message.lua
-- RPC based on protobuf 
local skynet = require 'skynet'
local snax = require 'skynet.snax'
local protobuf = require "protobuf"
local message_map = require 'message_map'

local message = {}

message.mapping = message_map.mapping

function message.unpack(msg, sz)
    local data = skynet.tostring(msg, sz)
    local netmsg = protobuf.decode("netmsg.NetMsg", data)
    if not netmsg then
        error("msg_unpack error")
    end
    return netmsg
end

function message.pack_raw(id, payload, code)
    local d = {id = id, payload = payload}
    if code ~= nil then d.code = code end
    return protobuf.encode("netmsg.NetMsg", d)
end

function message.pack(proto, data)
    local payload = protobuf.encode(proto, data)
    return message.pack_raw(proto, payload)
end

function message.dispatch(netmsg, ...)
    local id = netmsg.id
    local module, method = message_map.get_name(id)
    if not method then
        return message.pack_raw(-1, 'not found service', -1)
    end
    local ok, obj = pcall(snax.uniqueservice, module)
    if not ok then
        local msg = string.format('not found module %s', module)
        LOG_WARNING(msg)
        return message.pack_raw(id, msg, -1)
    end
    local proto_name = message_map.proto_name(module, method)
    ok, ret = pcall(obj.req[method], {name = proto_name, payload = netmsg.payload}, ...)
    if not ok then
        LOG_WARNING('call rpc service failed: %s', ret)
        return message.pack_raw(id, ret, -1)
    end
    return ret
end

function message.dispatch_game(netmsg, ...)
    local id = netmsg.id
    local module, method = message_map.get_name(id)
    if not method then
        return message.pack_raw(-1, 'not found service', -1)
    end
    local ok, obj = pcall(snax.uniqueservice, module)
    if not ok then
        local msg = string.format('not found module %s', module)
        LOG_WARNING(msg)
        return message.pack_raw(id, msg, -1)
    end
    local proto_name = message_map.proto_name(module, method)
    ok, ret = pcall(obj.post[method], {name = proto_name, payload = netmsg.payload}, ...)
    if not ok then
        LOG_WARNING('call rpc service failed: %s', ret)
        return message.pack_raw(id, string.format('post message to game failed: %s', ret))
    end
    return nil
end

return message
