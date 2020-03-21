package.path = package.path .. ";./service/?.lua;"
local skynet = require("skynet")
local service = require("skynet.service")
local redis = require("skynet.db.redis")
local redismgr = require("redis_server.manager")
require("skynet.manager")
require("common.export")
require("service_config.type")

local command = {
	servertype = SERVICE_TYPE.REDIS.ID, 	-- 服务类型
	servername = SERVICE_TYPE.REDIS.NAME,  	-- 服务名
	running = false,					-- 服务器状态
	redisConn = nil,					-- redis连接
	syncInterval = 30, 					-- 同步DB时间（单位·秒）
	conf = nil, 						-- redis配置
}

function command.START(conf)
	assert(conf ~= nil)
	command.conf = conf
	command.redisConn = redis.connect(command.conf)
	assert(command.redisConn ~= nil)
    if command.redisConn == nil then
        return 1, command.servername .. " fail"
	end
	
	math.randomseed(os.time())
	
	command.running = true

	redismgr.start(command.servername)

	-- 定时同步数据到dbserver
	skynet.fork(
		function(...)
			local ok = xpcall(
				command._syncToDbserver,
				__G__TRACKBACK__
			)
			if ok then
				skynet.error("_syncToDbserver exit")
			end
		end
	)

    return 0
end

function command.STOP()
	command.running = false
	
	redismgr.stop()

	command.redisConn:disconnect()
	command.redisdb = nil
	
    return 0
end

-- REDIS服务·消息处理接口
function command.MESSAGE(head, content)
	assert(head ~= nil and type(head) == "table")
    assert(content ~= nil and type(content) == "table")
	return redismgr.dispatch(command.redisConn, head, content)
end

-- 定时同步数据到数据库
function command._syncToDbserver()
    while command.running do
		skynet.sleep(100)
			
		local now = os.date("*t")
        -- dump(now, "系统时间")

		-- 每30秒同步一次服务器数据
		if math.fmod(now.sec, command.syncInterval) == 0 then
			
		end
    end
end

local function dispatch()
    skynet.dispatch(
        "lua",
        function(session, address, cmd, ...)
            cmd = cmd:upper()
            local f = command[cmd]
            assert(f)
            if f then
                skynet.ret(skynet.pack(f(...)))
            else
                skynet.error(string.format(command.servername .. " unknown command %s", tostring(cmd)))
            end
        end
    )
    skynet.register(command.servername)
end

skynet.start(dispatch)
