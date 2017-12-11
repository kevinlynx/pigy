local skynet = require "skynet"
local snax = require "skynet.snax"
local EntityFactory = require "EntityFactory"

local ent_room

function init(...)
    ent_room = EntityFactory.get("d_room")
    ent_room:init()
    ent_room:load()
end

function exit(...)
end

function response.get_nextid()
    return ent_room:getNextId()
end

function response.add(row)
    return ent_room:add(row)
end

function response.delete(row)
    return ent_room:delete(row)
end

function response.get_all()
    return ent_room:getAll()
end

function response.get(rid)
    return ent_room:get(rid)
end

