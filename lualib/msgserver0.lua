-- msgserver0.lua
-- a skynet msgserver without cache response
local skynet = require "skynet"
local netpack = require "skynet.netpack"
local crypt = require "skynet.crypt"
local socketdriver = require "skynet.socketdriver"
local gateserver = require 'snax.gateserver'
local assert = assert
local b64encode = crypt.base64encode
local b64decode = crypt.base64decode

local user_online = {} -- username: user
local connection = {} -- fd: user

local server = {}

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
}

function server.username(uid, subid, servername)
	return string.format("%s@%s#%s", b64encode(uid), b64encode(servername), b64encode(tostring(subid)))
end

function server.logout(username)
	local u = user_online[username]
	user_online[username] = nil
	if u.fd then
		gateserver.closeclient(u.fd)
		connection[u.fd] = nil
	end
end

function server.login(username, secret)
	assert(user_online[username] == nil)
	user_online[username] = {
		secret = secret,
		username = username
	}
end

function server.start(conf)
    local handler = {}
    local handshake = {} -- awaiting handshake client

    assert(conf.cmd_handler)
    -- compatible with skynet.msgserver
	local CMD = {
		login = assert(conf.login_handler),
		logout = assert(conf.logout_handler),
		kick = assert(conf.kick_handler),
	}

	function handler.command(cmd, source, ...)
        if CMD[cmd] then
            return CMD[cmd](...)
        else
		    return conf.cmd_handler(cmd, source, ...)
        end
	end

	function handler.open(source, gateconf)
		local servername = assert(gateconf.servername)
		return conf.register_handler(servername)
	end

    function handler.connect(fd, addr)
        handshake[fd] = addr
        gateserver.openclient(fd)
    end

    function handler.disconnect(fd)
        handshake[fd] = nil
		local c = connection[fd]
		if c then
			c.fd = nil
			connection[fd] = nil
			if conf.disconnect_handler then
				conf.disconnect_handler(c.username)
			end
		end
    end

	handler.error = handler.disconnect

	-- atomic , no yield
	local function do_auth(fd, message, addr)
		local username, hmac = string.match(message, "([^:]*):([^:]*)")
		local u = user_online[username]
		if u == nil then
			return string.format("404 User Not Found:%s", username)
		end
		hmac = b64decode(hmac)
		local text = username
		local v = crypt.hmac_hash(u.secret, text)
		if v ~= hmac then
			return "401 Unauthorized"
		end
		u.fd = fd
		u.ip = addr
		connection[fd] = u
	end

	local function auth(fd, addr, msg, sz)
		local message = netpack.tostring(msg, sz)
		local ok, result = pcall(do_auth, fd, message, addr)
		if not ok then
			skynet.error(result)
			result = "400 Bad Request"
		end
		local close = result ~= nil
		if result == nil then
			result = "200 OK"
		end
		socketdriver.send(fd, netpack.pack(result))
		if close then
			gateserver.closeclient(fd)
		end
	end

	local function do_request(fd, message)
		local u = assert(connection[fd], "invalid fd")
        local ok, result = pcall(conf.request_handler, u.username, message)
        result = result or ""
        if not ok then
            skynet.error(result)
        end
        local resp = string.pack(">s2", result)

		if connection[fd] then
			socketdriver.send(fd, resp)
		end
    end

	local function request(fd, msg, sz)
		local message = netpack.tostring(msg, sz)
		local ok, err = pcall(do_request, fd, message)
		-- not atomic, may yield
		if not ok then
			skynet.error(string.format("Invalid package %s : %s", err, message))
			if connection[fd] then
				gateserver.closeclient(fd)
			end
		end
	end

    function handler.message(fd, msg, sz)
        local addr = handshake[fd]
        if addr then
            auth(fd, addr, msg, sz)
            handshake[fd] = nil
        else
            request(fd, msg, sz)
        end
	end

	return gateserver.start(handler)
end

return server
