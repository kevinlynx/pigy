-- room.lua
local skynet = require 'skynet'
local snax = require 'skynet.snax'

local gid, game
local users = {}
local roomid

local command = {}

function command.start(id, gamelet)
    roomid = id
    gid = gamelet.id
    LOG_INFO('start room %d for game %d:%s', id, gid, gamelet.name)
    local ok, obj = pcall(snax.newservice, gamelet.name, skynet.self())
    game = obj
end

function command.user_enter(user)
    LOG_INFO('user %d enter room %d', user.userid, roomid)
    users[user.username] = user
    game.post.enter(user)
end

function command.user_leave(user)
    game.post.leave(user)
    users[user.username] = nil
end

function command.get_users()
    return users
end

function command.destroyable()
    return table.empty(users) 
end

function command.destroy()
    -- TODO: if destroyed by force, it should broadcast a destroyed messge to all users
    skynet.exit()
end

function command.get_info()
    return {id = roomid, gid = gid, user_count = table.size(users)}
end

function command.play_game(user, detail)
    game.post.play(user, detail)
end

skynet.start(function() 
    skynet.dispatch("lua", function(session, address, cmd, ...)
        local f = command[cmd]
        if f then
            skynet.ret(skynet.pack(f(...)))
        else
            error(string.format("Unknown command %s", tostring(cmd)))
        end
    end)
end)
