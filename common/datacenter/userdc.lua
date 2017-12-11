local skynet = require "skynet"
local snax = require "skynet.snax"
local EntityFactory = require "EntityFactory"

local entUser

function init(...)
    entUser = EntityFactory.get("d_user")
    entUser:init()
end

function exit(...)
end

function response.load(uid)
    entUser:load(uid)
end

function response.ensure(uid, nick)
    entUser:load(uid)
    entUser:add({uid = uid, nick = nick})
end

function response.getvalue(uid, key)
    return entUser:getValue(uid, key)
end

function response.setvalue(uid, key, value)
    return entUser:setValue(uid, key, value)
end

function response.add(row)
    return entUser:add(row)
end

function response.delete(row)
    return entUser:delete(row)
end

function response.get(uid)
    return entUser:get(uid)
end
