local skynet = require "skynet"
local protobuf = require "protobuf"
local socketdriver = require "skynet.socketdriver"

function do_redis(args, uid)
    local cmd = assert(args[1])
    args[1] = uid
    return skynet.call("redispool", "lua", cmd, table.unpack(args))
end

function LOG_DEBUG(fmt, ...)
    local msg = string.format(fmt, ...)
    local info = debug.getinfo(2)
    if info then
        msg = string.format("[%s:%d] %s", info.short_src, info.currentline, msg)
    end
    skynet.send("log", "lua", "debug", SERVICE_NAME, msg)
    return msg
end

function LOG_INFO(fmt, ...)
    local msg = string.format(fmt, ...)
    local info = debug.getinfo(2)
    if info then
        msg = string.format("[%s:%d] %s", info.short_src, info.currentline, msg)
    end
    skynet.send("log", "lua", "info", SERVICE_NAME, msg)
    return msg
end

function LOG_WARNING(fmt, ...)
    local msg = string.format(fmt, ...)
    local info = debug.getinfo(2)
    if info then
        msg = string.format("[%s:%d] %s", info.short_src, info.currentline, msg)
    end
    skynet.send("log", "lua", "warning", SERVICE_NAME, msg)
    return msg
end

function LOG_ERROR(fmt, ...)
    local msg = string.format(fmt, ...)
    local info = debug.getinfo(2)
    if info then
        msg = string.format("[%s:%d] %s", info.short_src, info.currentline, msg)
    end
    skynet.send("log", "lua", "error", SERVICE_NAME, msg)
    return msg
end

function LOG_FATAL(fmt, ...)
    local msg = string.format(fmt, ...)
    local info = debug.getinfo(2)
    if info then
        msg = string.format("[%s:%d] %s", info.short_src, info.currentline, msg)
    end
    skynet.send("log", "lua", "fatal", SERVICE_NAME, msg)
    return msg
end

function pb_encode(name, msg)
    local data = protobuf.encode(name, msg)
    if not data then
        LOG_ERROR("pb_encode error")
    end
    return data
end

function pb_decode(data)
    local msg = protobuf.decode(data.name, data.payload)
    if not msg then
        LOG_ERROR("pb_decode error")
        return
    end
    if data.uid then
        msg.uid = data.uid
    end
    return msg
end

function check( ... )
    -- body
end

function check_user_online(uid)
    return skynet.call("gated", "lua", "is_online", uid)
end

function send_client(fd, proto, data)
    local payload = pb_encode(proto, data)
    local msg = protobuf.encode("netmsg.NetMsg", { name = proto, payload = payload })
    if not msg then
        error("protobuf.encode error")
    end

    msg = msg .. string.pack(">BI4", 1, 9)
    msg = string.pack(">s2", msg)
    socketdriver.send(fd, msg)  
end
