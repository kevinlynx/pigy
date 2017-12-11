-- i_client.lua
-- interactive test client
package.cpath = "skynet/luaclib/?.so;luaclib/?.so"
local service_path = "./lualib/?.lua;" .. "./common/?.lua;" .. "./global/?.lua;" .. "./?.lua;" .. './test/?.lua'
package.path = "skynet/lualib/?.lua;skynet/service/?.lua;" .. service_path

require 'luaext'
local c_login = require 'c_login'
local c_hall = require 'c_hall'
local c_game = require 'c_game'
local socket = require "client.socket"
local util = require 'client_util'

local CMD = {}
local login_addr = {ip = '127.0.0.1', port = 5188}
local token = {
    server = "<not used>",
    pid = "123",
    sdkid = 1
}
local ls
local index = 1

local function help()
    print('> command list:')
    for k, v in pairs(CMD) do
        print(k)
    end
end

c_login.set_addr(login_addr.ip, login_addr.port)

function CMD.login()
    code, ls = c_login.login(token.pid, token.server, token.sdkid)
    assert(code == 200)
    print('login ok, username: ', ls.username)
    print('get hall server:', ls.server)
end

function CMD.register(sdkid, pid, password)
    if not sdkid or not pid then
        print('require skdid/pid')
        return
    end
    c_login.register(tonumber(sdkid), pid, password)
end

function CMD.bind(sdkid1, pid1, sdkid2, pid2)
    if not sdkid1 or not pid1 or not sdkid2 or not pid2 then
        print('require 2 sdkid/pid')
        return
    end
    c_login.bind(tonumber(sdkid1), pid1, tonumber(sdkid2), pid2)
end

local function get_user()
    local user_info = c_hall.get_user()
    print(user_info)
    if user_info.room.rid > 0 then
        print(string.format('user has room info: %d:%s', user_info.room.rid, user_info.room.sname))
    end
    return user_info
end

function CMD.get_user()
    get_user()
end

function CMD.enter_hall()
    local ret = c_hall.connect(ls, index)
    print('enter hall result: ', ret)
    local uinfo = get_user()
    if uinfo.room.rid > 0 then
        print('has entered room, reconn room ...')
        CMD.reconn_room()
    end
end

function CMD.reconn_hall()
    c_hall.shutdown()
    local state = ls
    index = index + 1
    local ret = c_hall.connect(state, index)
    print('reconnect hall result: ', ret)
    get_user()
end

function CMD.stay_hall()
    CMD.login()
    CMD.enter_hall()
end

function CMD.game_list()
    local list = c_hall.get_game_list()
    print('game list:')
    for _, g in ipairs(list.games) do
        print(string.format('game id: %d', g.gid))
        for _, r in ipairs(g.rooms) do
            print(string.format(' > room %d on %s', r.rid, r.sname))
        end
    end
end

function CMD.create_room(id)
    if not id then
        print('require game id')
        return
    end
    local rid, server = c_hall.create_room(id)
    print(string.format('created room id: %d, server: %s:%d', rid, server.ip, server.port))
    local ok, msg = c_game.handshake(server.ip, server.port, ls.secret, ls.username)
    print(string.format('handshake to game server response: %s', msg))
    c_game.enter_game(rid)
    c_game.send_game_msg('hello world')
    local msg = c_game.recv_game_msg()
    print('recv game message:' .. msg)
end

function CMD.select_room(rid, sname)
    local server = c_hall.select_room(rid, sname)
    print(string.format('select room got server: %s:%d', server.ip, server.port))
    local ok, msg = c_game.handshake(server.ip, server.port, ls.secret, ls.username)
    print(string.format('handshake to game server response: %s', msg))
    c_game.enter_game(rid)
    c_game.send_game_msg('hello world')
    local msg = c_game.recv_game_msg()
    print('recv game message:' .. msg)
end

function CMD.reconn_room()
    local server, rid = c_hall.reconn_room()
    local ok, msg = c_game.handshake(server.ip, server.port, ls.secret, ls.username)
    print(string.format('handshake to game server response: %s', msg))
    c_game.enter_game(rid)
    c_game.send_game_msg('hello world')
    local msg = c_game.recv_game_msg()
    print('recv game message:' .. msg)
end

function CMD.leave_room()
    local code = c_hall.leave_room()
    print('leave room ret:' .. code)
end

function CMD.destroy_room(id)
    if not id then
        print('require room id')
        return
    end
    local code = c_hall.destroy_room(id)
    print('destroy room code: ' .. tostring(code))
end

local function run_command(cmd, ...)
    if CMD[cmd] then
        CMD[cmd](...)
    else
        help()
    end
end

while true do
    local cmd = socket.readstdin()
    if cmd then
        if cmd == "quit" then
            return
        else
            local secs = string.split(cmd, ' ')
            run_command(secs[1], table.unpack(secs, 2))
        end
    else
        socket.usleep(100)
    end
end
