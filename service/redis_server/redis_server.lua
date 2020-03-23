package.path = package.path .. ";./service/?.lua;"
local skynet = require("skynet")
local service = require("skynet.service")
local redis = require("skynet.db.redis")
local mgr = require("redis_server.manager")
require("skynet.manager")
require("common.export")
require("service_config.type")

local CMD = {
	servertype = SERVICE_TYPE.REDIS.ID, 	-- 服务类型
	servername = SERVICE_TYPE.REDIS.NAME,  	-- 服务名
	running = false,					-- 服务器状态
	redisConn = nil,					-- redis连接
	syncInterval = 30, 					-- 同步DB时间（单位·秒）
	conf = nil, 						-- redis配置
}

function CMD.START(conf)
	assert(conf ~= nil)
	CMD.conf = conf
	CMD.redisConn = redis.connect(CMD.conf)
	assert(CMD.redisConn ~= nil)
    if CMD.redisConn == nil then
        return 1, CMD.servername .. " fail"
	end
	
	math.randomseed(os.time())
	
	CMD.running = true

	mgr.start(CMD.servername)

	-- 定时同步数据到dbserver
	skynet.fork(
		function(...)
			local ok = xpcall(
				CMD._syncToDbserver,
				__G__TRACKBACK__
			)
			if ok then
				skynet.error("_syncToDbserver exit")
			end
		end
	)

    return 0
end

function CMD.STOP()
	CMD.running = false
	
	mgr.stop()

	CMD.redisConn:disconnect()
	CMD.redisdb = nil
	
    return 0
end

-- REDIS服务·消息处理接口
function CMD.MESSAGE(head, content)
	assert(head ~= nil and type(head) == "table")
    assert(content ~= nil and type(content) == "table")
	return mgr.dispatch(CMD.redisConn, head, content)
end

-- 定时同步数据到数据库
function CMD._syncToDbserver()
    while CMD.running do
		skynet.sleep(100)
			
		local now = os.date("*t")
        -- dump(now, "系统时间")

		-- 每30秒同步一次服务器数据
		if math.fmod(now.sec, CMD.syncInterval) == 0 then
			
		end
    end
end

local function dispatch()
    skynet.dispatch(
        "lua",
        function(session, address, cmd, ...)
            cmd = cmd:upper()
            local f = CMD[cmd]
            assert(f)
            if f then
                skynet.ret(skynet.pack(f(...)))
            else
                skynet.error(string.format(CMD.servername .. " unknown CMD %s", tostring(cmd)))
            end
        end
    )
    skynet.register(CMD.servername)
end

skynet.start(dispatch)
