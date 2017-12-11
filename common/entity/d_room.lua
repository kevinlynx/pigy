local CommonEntity = require "CommonEntity"

local EntityType = class("d_room", CommonEntity)

function EntityType:ctor()
    EntityType.super.ctor(self)
    self.tbname = "d_room"
end

return EntityType.new()
