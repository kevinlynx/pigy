local skynet = require "skynet"
local Entity = require "Entity"

-- CommonEntity
local CommonEntity = class("CommonEntity", Entity)

function CommonEntity:ctor()
    CommonEntity.super.ctor(self)
    self.type = 3
end

function CommonEntity:load()
    if table.empty(self.recordset) then
        local rs = skynet.call("dbmgr", "lua", "get_common", self.tbname)
        if rs then
            self.recordset = rs
        end
    end

end

function CommonEntity:add(row, nosync)
    local key = self:getKey(row)
    if self.recordset[key] then return end

    local id = row[self.pk]
    if not id or id == 0 then
        id = self:getNextId()
        row[self.pk] = id
    end

    local ret = skynet.call("dbmgr", "lua", "add", self.tbname, row, self.type, nosync)

    if ret then
        self.recordset[key] = row
    end

    return true
end

function CommonEntity:delete(row, nosync)
    local key = self:getKey(row)
    if not self.recordset[key] then return end

    local ret = skynet.call("dbmgr", "lua", "delete", self.tbname, row, self.type, nosync)

    if ret then
        self.recordset[key] = nil
    end

    return true
end

function CommonEntity:remove(row)
    local key = self:getKey(row)
    self.recordset[key] = nil
    return true
end

function CommonEntity:update(row, nosync)
    local key = self:getKey(row)
    if not self.recordset[key] then return end

    local ret = skynet.call("dbmgr", "lua", "update", self.tbname, row, self.type, nosync)

    if ret then
        for k, v in pairs(row) do
            self.recordset[key][k] = v
        end
    end

    return true
end

function CommonEntity:get(...)
    local t = { ... }
    assert(#t > 0)
    local key
    if #t == 1 then
        key = t[1]
    else
        key = ""
        for i = 1, #t do
            if i > 1 then
                key = key .. ":"
            end
            key = key .. tostring(t[i])
        end
    end

    return self.recordset[key] or {}
end

function CommonEntity:getValue(id, field)
    local record = self:get(id)
    if record then
        return record[field]
    end
end

function CommonEntity:setValue(id, field, data)
    local record = {}
    record[self.pkfield] = id
    record[field] = data
    self:update(record)
end

function CommonEntity:getKey(row)
    local fields = string.split(self.key, ",")
    local key
    for i=1, #fields do
        if i == 1 then
            key = row[fields[i]]
        else
            key = key .. ":" .. row[fields[i]]
        end
    end

    return tonumber(key) or key
end

function CommonEntity:getAll( )
    return self.recordset
end

return CommonEntity
