local skynet = require "skynet"
require "skynet.manager"
local cluster = require "skynet.cluster"
local logger = require "logger"

--id
local svr_info

--代理
local proxy

local NORET = {}

local function watch()
	logger.trace(string.format("[%s] keep-alive",svr_info.cluster.name))
	skynet.response()
end

-- 不允许上层对下层进行call调用，影响性能
-- local function cluster_call(command,...)
-- 	if proxy then
-- 		return pcall(skynet.call,proxy,"lua",command,...)
-- 	end
-- end

local function cluster_send(command,...)
	if proxy then
		pcall(skynet.send,proxy,"lua",command,...)
	end
end

----------------------------------------------------
local handler = {}

--保持
function handler.keepalive()
	watch()
	return NORET
end

--请求链接服务中心
function handler.open(info)
    svr_info = info
    proxy = cluster.proxy(info.cluster.name,info.service)
    return skynet.self()
end

--发送消息
function handler.send(...)
    return cluster_send(...)
end

skynet.init(function()
    
end)

skynet.start(function()
	skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
		skynet.error("master_proxy recved cmd",cmd,...)
        if cmd == "socket" then
			local f = SOCKET[subcmd]
			f(...) 
			-- socket api don't need return
		else
			local f = assert(handler[cmd],cmd)
			if session == 0 then
				f(subcmd, ...)
			else
				local r = f(subcmd, ...)
				if r ~= NORET then
					skynet.ret(skynet.pack(r))
				end
			end
		end
  end)
end)