-- message_map.lua
-- map between message id to RPC (module + mehtod)
local messageids = require 'messageid'

local message = {_ids = {}, _names = {}}

local function full_name(module, method)
    return module .. '.' .. method
end

local function mapping(t)
    local ids = assert(messageids[t])
    local base = ids[1]
    for k, v in pairs(ids) do
        if type(k) == 'string' then
            local id = base + v
            message._ids[id] = {module = t, method = k}
            message._names[full_name(t, k)] = id
        end
    end
end

function message.mapping(...)
    local ts = {...}
    for _, v in ipairs(ts) do
        mapping(v)
    end
end

function message.get_id(proto_name)
    return message._names[proto_name]
end

function message.get_name(id)
    local mm = message._ids[id]
    if not mm then return nil end
    return mm.module, mm.method
end

function message.proto_name(module, method)
    return full_name(module, method)
end

return message

