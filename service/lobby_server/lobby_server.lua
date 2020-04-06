local skynet = require("skynet")
local service = require("skynet.service")
local mgr = require("lobby_manager")
local utils = require("utils")
require("skynet.manager")
require("service_type")

local handler = {
	servicetype = SERVICE_TYPE.LOBBY.ID, 	-- 服务类型
    servername = SERVICE_TYPE.LOBBY.NAME,  	-- 服务名
    debug = false,
}

function handler.start(content)
    assert(content ~= nil, "content is nil")
	math.randomseed(os.time())

    handler.debug = content.debug

	mgr.start(handler.servername, handler.debug)

    return 0
end

function handler.stop() 
    mgr.stop()
    skynet.exit();
    return 0
end

-- 登录服·send消息处理接口
function handler.dispatch_send_message(head, content)
	mgr.dispatch(head, content)
end

-- 登录服·call消息处理接口
function handler.dispatch_call_message(head, content)
	return mgr.dispatch(head, content)
end

local function dispatch()
    skynet.dispatch(
        "lua",
        function(session, address, cmd, ...)
            local f = handler[cmd]
            assert(f)
            if session == 0 then
                f(...)
            else
                skynet.ret(skynet.pack(f(...)))
            end
        end
    )
    skynet.register(handler.servername)
end

skynet.start(dispatch)
