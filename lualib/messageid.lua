-- messageid.lua
-- define all message id mapping to RPC methods
-- TODO: to write a DSL parser 
local hall = {
    100,
    'Hall',
    GetGameList = 1,
    CreateRoom = 2,
    DestroyRoom = 3,
    SelectRoom = 4,
    ReconnRoom = 5,
    LeaveRoom = 6,
    GetUserInfo = 7,
}

local game = {
    500,
    'Game',
    EnterRoom = 1,
    PlayGame = 2,
}

return {hall = hall, game = game}
