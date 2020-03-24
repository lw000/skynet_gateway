package.path = package.path .. ";./service/?.lua;"
local skynet = require("skynet")
local service = require("skynet.service")
local mgr = require("lobby_server.lobby_manager")
require("skynet.manager")
require("common.export")
require("service_config.type")

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

-- 登录服·消息处理接口
function CMD.on_server_message(head, content)
    assert(head ~= nil and type(head)== "table")
    assert(content ~= nil and type(content)== "table")
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
