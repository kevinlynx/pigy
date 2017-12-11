skynetroot = "./skynet/"
thread = 8
logger = nil
logpath = "."
harbor = 0
start = "main"	-- main script
bootstrap = "snlua bootstrap"	-- The service for bootstrap

cluster = "./cluster/clustername.lua"
hallservers = "hall"

log_dirname = "log"
log_basename = "login"

loginservice = "./login/?.lua;" ..
			   "./common/?.lua;" ..
			   "./common/datacenter/?.lua"

luaservice = skynetroot .. "service/?.lua;" .. loginservice
-- snax standard services
snax = loginservice

lualoader = skynetroot .. "lualib/loader.lua"
preload = "./global/preload.lua"	-- run preload.lua before every lua service run

cpath = skynetroot .. "cservice/?.so"

lua_path = skynetroot .. "lualib/?.lua;" ..
		   "./lualib/?.lua;" ..
		   "./global/?.lua;" ..
		   "./common/entitybase/?.lua;" ..
		   "./common/entity/?.lua"

lua_cpath = skynetroot .. "luaclib/?.so;" .. "./luaclib/?.so"

--daemon = "./login.pid"

port = $PIGY_PORT				

mysql_maxconn = 10
mysql_host = "$PIGY_MYSQL_HOST"
mysql_port = $PIGY_MYSQL_PORT
mysql_db = "$PIGY_MYSQL_DB"
mysql_user = "$PIGY_MYSQL_USER"
mysql_pwd = "$PIGY_MYSQL_PWD"

redis_maxinst = 1

redis_host1 = "127.0.0.1"
redis_port1 = 6379
redis_auth1 = "123456"

