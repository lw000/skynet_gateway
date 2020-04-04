local skynet = require("skynet")
local service = require("skynet.service")
local mgr = require("lobby_manager")
local utils = require("utils")
require("skynet.manager")
require("service_type")

local CMD = {
	servicetype = SERVICE_TYPE.LOBBY.ID, 	-- 服务类型
    servername = SERVICE_TYPE.LOBBY.NAME,  	-- 服务名
    debug = false,
}

function CMD.start(content)
	math.randomseed(os.time())

    CMD.debug = content.debug

	mgr.start(CMD.servername, CMD.debug)

    return 0
end

function CMD.stop() 
    mgr.stop()
    return 0
end

-- 登录服·send消息处理接口
function CMD.dispatch_send_message(head, content)
	mgr.dispatch(head, content)
end

-- 登录服·call消息处理接口
function CMD.dispatch_call_message(head, content)
	return mgr.dispatch(head, content)
end

local function dispatch()
    skynet.dispatch(
        "lua",
        function(session, address, cmd, ...)
            local f = CMD[cmd]
            assert(f)
            if session == 0 then
                f(...)
            else
                skynet.ret(skynet.pack(f(...)))
            end
        end
    )
    skynet.register(CMD.servername)
end

skynet.start(dispatch)
