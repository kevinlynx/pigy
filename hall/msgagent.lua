-- msgagent.lua
local skynet = require "skynet"
local snax = require "skynet.snax"
local message = require 'message'
local protobuf = require 'protobuf'

local gate
local user

local CMD = {}

skynet.register_protocol {
    name = "client",
    id = skynet.PTYPE_CLIENT,
    unpack = message.unpack,
    dispatch = function (_, _, netmsg)
        local ret = message.dispatch(netmsg, user)
        skynet.ret(ret)
    end
}

local function load_user_detail(r)
    local roomdc = snax.uniqueservice('roomdc')
    local room = r.room > 0 and roomdc.req.get(r.room) or nil
    if room then
        user.room = {rid = r.room, sname = room.server}
        LOG_INFO('associate room to login user, uid %d, rid %d, sname %s',
            r.uid, r.room, room.server)
    end
end

function CMD.login(source, uname, uid, sid, secret)
    -- you may use secret to make a encrypted data stream
    skynet.error(string.format("%s is login", uid))
    gate = source
    user = {
        userid = uid,
        subid = sid,
        username = uname,
        secret = secret,
        service = skynet.self(),
    }
    local userdc = snax.uniqueservice('userdc')   
    -- load user if exist, otherwise register 
    userdc.req.ensure(uid, tostring(uid))
    load_user_detail(userdc.req.get(uid))
end

function CMD.set_room(_, rid, sname)
    LOG_INFO('set room [%d-%s] to user %d', rid, sname, user.userid)
    local userdc = snax.uniqueservice('userdc')   
    userdc.req.setvalue(user.userid, 'room', rid)
    user.room = {rid = rid, sname = sname}
end

function CMD.get_room(_)
    return user.room
end

local function logout()
    if gate then
        skynet.call(gate, "lua", "logout", user.userid, user.subid)
    end
    skynet.exit()
end

function CMD.logout(source)
    -- NOTICE: The logout MAY be reentry
    skynet.error(string.format("%s is logout", user.userid))
    logout()
end

function CMD.afk(source)
    -- the connection is broken, but the user may back
    skynet.error(string.format("AFK"))
end

skynet.start(function()
    message.mapping('hall')
    -- If you want to fork a work thread , you MUST do it in CMD.login
    skynet.dispatch("lua", function(session, source, command, ...)
        local f = assert(CMD[command])
        skynet.ret(skynet.pack(f(source, ...)))
    end)
    protobuf.register_file("./protocol/netmsg.pb")
end)
