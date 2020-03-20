package.path = package.path .. ";./service/?.lua;"
local skynet = require("skynet")
local service = require("skynet.service")
local logonmgr = require("logon_server.manager")
require("skynet.manager")
require("common.export")
require("service_config.define")

local command = {
	servertype = SERVICE_CONF.LOGON.TYPE, 	-- 服务类型
	servername = SERVICE_CONF.LOGON.NAME,  	-- 服务名
	running = false,						-- 服务器状态
}

function command.START()
	math.randomseed(os.time())
	
	command.running = true

	logonmgr.start(command.servername)

    return 0
end

function command.STOP()
	command.running = false
	logonmgr.stop()
    return 0
end

-- 登录服·消息处理接口
function command.MESSAGE(head, content)
    assert(head ~= nil and type(head) == "table")
    assert(content ~= nil and type(content) == "table")
	return logonmgr.dispatch(head, content)
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
