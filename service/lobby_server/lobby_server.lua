package.path = package.path .. ";./service/?.lua;"
local skynet = require("skynet")
local service = require("skynet.service")
local lobbymgr = require("lobby_server.manager")
require("skynet.manager")
require("common.export")
require("service_config.type")

local command = {
	servicetype = SERVICE_TYPE.LOBBY.ID, 	-- 服务类型
	servername = SERVICE_TYPE.LOBBY.NAME,  	-- 服务名
}

function command.START()
	math.randomseed(os.time())

	lobbymgr.start(command.servername)

    return 0
end

function command.STOP() 
    lobbymgr.stop()
    return 0
end

-- 登录服·消息处理接口
function command.MESSAGE(head, content)
    assert(head ~= nil and type(head)== "table")
    assert(content ~= nil and type(content)== "table")
	return lobbymgr.dispatch(head, content)
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
