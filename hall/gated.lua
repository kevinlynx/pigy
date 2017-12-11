-- gated.lua
local msgserver = require "msgserver0"
require 'skynet.manager'
local crypt = require "skynet.crypt"
local cluster = require "skynet.cluster"
local skynet = require "skynet"

local users = {} -- uid -> u
local username_map = {} -- username -> u
local internal_id = 0 -- disable multi login
local starttm = skynet.time()

local server = {}
local CMD = {}

local function do_login(uid, secret)
    local username = msgserver.username(uid, internal_id, NODE_NAME)
    local agent = skynet.newservice "msgagent"

    LOG_INFO('user (uid:%d) logined subid: %d, username: %s', uid, internal_id, username)

    local u = {
        username = username,
        agent = agent,
        uid = uid,
        subid = internal_id,
        secret = secret,
    }

    -- trash subid (no used)
    skynet.call(agent, "lua", "login", username, uid, internal_id, secret)

    users[uid] = u
    username_map[username] = u
    msgserver.login(username, secret)
end

-- login server disallow multi login, so login_handler never be reentry
-- call by login server
function server.login_handler(uid, secret)
    if users[uid] then
        local errmsg = string.format("%d is already login", uid)
        LOG_ERROR(errmsg)
        error(errmsg)
    end
    do_login(uid, secret)
    -- you should return unique subid
    return internal_id
end

-- call by agent
function server.logout_handler(uid, subid)
    local u = users[uid]
    if u then
        local username = msgserver.username(uid, subid, NODE_NAME)
        assert(u.username == username)
        msgserver.logout(u.username)
        users[uid] = nil
        username_map[u.username] = nil
        pcall(cluster.call, "login", ".login_master", "logout", uid, subid)
    end
end

-- call by login server
function server.kick_handler(uid, subid)
    local u = users[uid]
    if u then
        local username = msgserver.username(uid, subid, NODE_NAME)
        assert(u.username == username)
        -- NOTICE: logout may call skynet.exit, so you should use pcall.
        pcall(skynet.call, u.agent, "lua", "logout")
    else
        -- in case this server crashed and login server still keep the user
        pcall(cluster.call, "login", ".login_master", "logout", uid, subid)
    end
end

-- call by self (when socket disconnect)
function server.disconnect_handler(username)
    local u = username_map[username]
    if u then
        skynet.call(u.agent, "lua", "afk")
    end
end

-- call by self (when recv a request from client)
function server.request_handler(username, msg)
    local u = username_map[username]
    return skynet.tostring(skynet.rawcall(u.agent, "client", msg))
end

-- call by self (when gate open)
function server.register_handler(name)
    skynet.register(SERVICE_NAME) 
end

function server.cmd_handler(cmd, source, ...)
    local f = assert(CMD[cmd])
    return f(...)
end

local function get_simple_users()
    local s_users = {}
    for uid, user in pairs(users) do
        s_users[uid] = {secret = user.secret, subid = user.subid}
    end
    return s_users
end

function CMD.ping()
    local ap = skynet.getenv('ap_ip') .. ':' .. skynet.getenv('port')
    local ret = {ap = ap, handshake = starttm, users = get_simple_users()}
    return ret
end

function CMD.recover_login(uid, secret)
    LOG_INFO('recover user login [%d]', uid)
    -- TODO: this maybe happen when some user login at recoving process.
    assert(users[uid] == nil)
    do_login(uid, secret)
    return internal_id
end

msgserver.start(server)

