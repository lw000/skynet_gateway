package.path = package.path .. ";./service/?.lua;"
local skynet = require("skynet")
local service = require("skynet.service")
local logonmgr = require("logon_server.manager")
require("skynet.manager")
require("common.export")
require("service_config.type")

local command = {
	servicetype = SERVICE_TYPE.LOGON.ID, 	-- 服务类型
	servername = SERVICE_TYPE.LOGON.NAME,  	-- 服务名
	running = false,						-- 服务器状态
}

function command.START()
	math.randomseed(os.time())
	
	command.running = true

	logonmgr.start(command.servername)

    skynet.error(command.servername .. " start")
    return 0
end

function command.STOP()
    command.running = false
    
    logonmgr.stop()
    
    skynet.error(command.servername .. " stop")
    return 0
end

-- 登录服·消息处理接口
function command.MESSAGE(head, content)
    assert(head ~= nil and type(head)== "table")
    assert(content ~= nil and type(content)== "table")
    assert(head.mid ~= nil and head.mid >= 0)
    assert(head.mid ~= nil and head.sid >= 0)
    
    if head.mid ~= LOGON_CMD.MDM then
		local errmsg = "unknown " .. command.servername .. " message command"
		skynet.error(errmsg)
		return 1, errmsg
    end

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
