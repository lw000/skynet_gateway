package.path = package.path .. ";./service/?.lua;"
local skynet = require "skynet"
require "skynet.manager"
local cluster = require "skynet.cluster"
local snax = require "skynet.snax"
local logger = require "sharelib.logger"
require("common.export")

--
local is_first = true
--id
local svrid = nil
--代理
local proxy = nil

local error = nil
local keepalive = nil

local function master_call(command, ...)
	local args = {...}
	dump(args, "args")
	skynet.error("proxy", proxy)
	if proxy then
		return pcall(skynet.call, proxy, "lua",command, ...)
	else
		return pcall(cluster.call, "master", ".master_service", command, ...)
	end
end

local function master_send(command, ...)
	if proxy then
		pcall(skynet.send, proxy, "lua", command, ...)
	else
		pcall(cluster.send, "master", ".master_service", command, ...)
	end
end

local function on_load_config(config)
	dump(config,"config")

	skynet.error("on_load_config:",config.cluster.name,config.cluster.addr,config.tcpservice)
	if is_first then
		-- 注册自身节点
		cluster.reload( {[config.cluster.name] = config.cluster.addr} )
		cluster.open(config.cluster.name)
		is_first = nil
	end

	-- register
	local reg_info = {
		svrid = svrid,
		cluster = config.cluster,
		service = skynet.self(),
	}
	local suc,ret = master_call("register_gate",reg_info)
	if suc then
		if not ret then
			logger.trace("注册网关失败")
			return
		end
		skynet.error("注册网关成功",ret)
		proxy = cluster.proxy("master",ret)
		return proxy
	else
		logger.trace("注册网关异常",suc,ret)
		return
	end
end

--检查链接
local function connect()
	local suc, ret = master_call("get_gate_config", svrid)
	if suc  then
		if not ret then
			logger.trace("获取网关配置失败")
			return
		end
		dump(ret,"ret")
		return on_load_config(ret)
	end
end

error = function()
	proxy = nil

	skynet.fork(function()
		while(not connect()) do
			skynet.sleep(300)
		end
		keepalive()
	end)
end

keepalive = function()
	skynet.fork(function()
		logger.trace("中心服务 keepalive")
		local suc,ret = master_call("keepalive")
		if( not suc ) then
			logger.trace("中心服务连接断开")
			--连接异常
			error()
		end
	end)
end
----------------------------------------------------------------------------
----------------------------------------------------------------------------
--消息处理
local handler = {}

--请求链接服务中心
function handler.open(id)
	svrid = id
	proxy = nil
	if(not connect()) then
		error()
	else
		keepalive()
	end
end

skynet.init(function()
	--给当前服务起一个名字
	skynet.register(".master_proxy")
end)

skynet.start(function()
	skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
		-- skynet.error(session, source, cmd, subcmd, ...)
		if cmd == "register" then
			local f = SOCKET[subcmd]
			f(...) 
			-- socket api don't need return
		else
			local f = assert(handler[cmd])
			skynet.ret(skynet.pack(f(subcmd, ...)))
		end
	end)
end)