package.path = package.path .. ";./service/?.lua;"
local skynet = require("skynet")
local service = require("skynet.service")
local logonmgr = require("logon_server.logon_manager")
require("skynet.manager")
require("common.export")
require("core.define")

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
function command.MESSAGE(mid, sid, content)
	-- skynet.error(string.format(command.servername .. ":> mid=%d sid=%d", mid, sid))
	if mid ~= LOGON_CMD.MDM_LOGON then
		local errmsg = "unknown " .. command.servername .. " message command"
		skynet.error(errmsg)
		return -1, errmsg
	end
	return logonmgr.dispatch(mid, sid, content)
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
