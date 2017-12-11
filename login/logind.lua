-- logind.lua
-- pigybug
local login = require "loginserverx"
local crypt = require "skynet.crypt"
local skynet = require "skynet"
local snax = require "skynet.snax"
local cluster = require "skynet.cluster"
local msgserver = require 'snax.msgserver'

local server = {
    host = "0.0.0.0",
    port = tonumber(skynet.getenv("port")),
    multilogin = false, -- disallow multilogin
    name = "login_master",
    instance = 16,
}

local SDKID_GUEST = 2
local user_online = {}
local hall_servers = {} -- name: {ap: ap, handhsake: tm}

local function register(sdkid, pid, password)
    local account_dc = snax.uniqueservice("accountdc")
    local acc = account_dc.req.get(sdkid, pid)
    if not table.empty(acc) then
        return false
    end
    local uid = account_dc.req.get_nextid()
    if uid < 1 then
        error(LOG_ERROR("register account get nextid failed"))
    end
    local row = { id = uid, pid = pid, sdkid = sdkid, password = password }
    local ret = account_dc.req.add(row)
    if not ret then
        error(LOG_ERROR("register account failed"))
    end
    LOG_INFO("register account succ uid=%d", uid)
    return true
end

local function bind(sdkid1, pid1, sdkid2, pid2, password)
    local account_dc = snax.uniqueservice("accountdc")
    local acc1 = account_dc.req.get(sdkid1, pid1)
    local acc2 = account_dc.req.get(sdkid2, pid2)
    if not table.empty(acc2) then
        error(LOG_WARNING('bind an existing account (%d,%s)', sdkid1, pid1))
    end
    if table.empty(acc1) then
        LOG_WARNING('bind account not exist (%d,%s)', sdkid1, pid1)
        return false
    end
    local id = acc1.id
    -- WTF! because sdkid,pid is uniq index
    account_dc.req.delete(acc1)
    acc1.pid = pid2
    acc1.sdkid = sdkid2
    acc1.password = password
    local ok = account_dc.req.add(acc1)
    LOG_INFO('bind account (%d,%s) by (%d,%s)', sdkid1, pid1, sdkid2, pid2)
    return ok
end

local function auth(pid, sdkid, token)
    local account_dc = snax.uniqueservice("accountdc")
    local account = account_dc.req.get(sdkid, pid)
    if table.empty(account) then
        return false
    end
    local t = crypt.base64encode(account.pid .. account.password)
    if t ~= token then
        error('auth failed')
    end
    return true, account.id
end

local function select_hall(uid)
    local names = table.indices(hall_servers)
    local size = table.size(hall_servers)
    local name = names[1 + uid % size]
    return hall_servers[name]
end

-- return false if user not registered yet
function server.auth_handler(args)
    local ret = string.split(args, ":")
    assert(#ret == 4)
    local server = ret[1]
    local token = ret[2]
    local sdkid = tonumber(ret[3])
    local pid = ret[4]

    LOG_INFO("auth_handler is performing server=%s token=%s sdkid=%d pid=%s", server, token, sdkid, pid)

    local ok, uid = auth(pid, sdkid, token)
    return ok, server, uid
end

-- called in login master
function server.login_handler(_, uid, secret)
    local server_pack = select_hall(uid)
    assert(server_pack)
    local server = server_pack.name
    LOG_INFO(string.format("%d@%s is login, secret is %s", uid, server, crypt.hexencode(secret)))
    -- only one can login, because disallow multilogin
    local last = user_online[uid]
    if last then
        LOG_INFO("call hallserver %s to kick uid=%d subid=%d ...", last.server, uid, last.subid)
        local ok = pcall(cluster.call, last.server, "gated", "kick", uid, last.subid)
        if not ok then
            user_online[uid] = nil
        end
    end

    -- the user may re-login after `pcall' above
    if user_online[uid] then
        error(string.format("user %d is already online", uid))
    end

    LOG_INFO("uid=%d is logging to hallserver %s ...", uid, server)

    local ok, subid = pcall(cluster.call, server, "gated", "login", uid, secret)
    if not ok then
        error(string.format("login hall server [%s] error", server))
    end

    user_online[uid] = { subid = subid, server = server, secret = secret }
    -- client will take `username' to msgserver to login
    return msgserver.username(uid, subid, server) .. ' ' .. server_pack.ap
end

local METHODS = {}

-- sdkid:username:password
-- sdkid:pid:
function METHODS.register(sdkid, pid, password)
    local ok = register(tonumber(sdkid), pid, password or '')
    return ok and '200 OK\n' or '406 Exists\n'
end

-- sdkid1:pid1:sdkid2:pid2:password, bind pid2 to pid1, update pid1
function METHODS.bind(sdkid1, pid1, sdkid2, pid2, password)
    if tonumber(sdkid1) ~= SDKID_GUEST then
        return '403 Forbidden\n'
    end
    local ok = bind(tonumber(sdkid1), pid1, tonumber(sdkid2), pid2, password or '')
    return ok and '200 OK\n' or '404 Acc Not Found\n'
end

-- called in login slave
function server.method_handler(method, line)
    if METHODS[method] == nil then
        error('method not found')
    end
    return METHODS[method](table.unpack(string.split(line, ':')))
end

local CMD = {}

function CMD.logout(uid, subid)
    local u = user_online[uid]
    if u then
        LOG_INFO(string.format("%d@%s#%d is logout", uid, u.server, subid))
        user_online[uid] = nil
    end
end

local function recover_login(server, users)
    LOG_INFO('recover login users from server [%s]', server)
    for uid, user in pairs(users) do
        if user_online[uid] == nil then
            LOG_INFO('recover user (%d)', uid)
            user_online[uid] = {subid = user.subid, server = server, secret = user.secret}
        end
    end
end

local function recover_hall(server)
    LOG_INFO('recover hall server users [%s]', server)
    for uid, user in pairs(user_online) do 
        if user.server == server then
            local ok, subid = pcall(cluster.call, server, "gated", "recover_login", uid, user.secret)
            if not ok then
                LOG_ERROR('recover user (%d) on server [%s] failed: %s', uid, server, subid)
            end
        end
    end
end

local function update_hall_state()
    local names = table.indices(hall_servers)
    for _, server in ipairs(names) do
        local ok, ret = pcall(cluster.call, server, 'gated', 'ping')
        if ok then
            local state = hall_servers[server]
            if not state.handhsake then 
                -- first handshake on login
                recover_login(server, ret.users)
                hall_servers[server] = {name = server, ap = ret.ap, handshake = ret.handshake}
            else
                if state.handshake ~= ret.handshake then
                    -- hall restart
                    recover_hall(server)
                    hall_servers[server].handshake = ret.handshake
                end
            end
        end
    end
end

function CMD.start()
    skynet.error('logind start...')
    snax.uniqueservice("accountdc")
    local serverstr = skynet.getenv('hallservers')
    local servers = string.split(serverstr, ';')
    for _, server in ipairs(servers) do
        hall_servers[server] = {name = server}
    end
    update_hall_state()
    skynet.fork(function ()
        while true do
            skynet.sleep(500) -- 5s
            update_hall_state()
        end
    end)
    skynet.error(hall_servers)
end

function server.command_handler(command, source, ...)
    local f = assert(CMD[command])
    return f(source, ...)
end

login(server)
