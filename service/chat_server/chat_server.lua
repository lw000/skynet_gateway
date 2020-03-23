package.path = package.path .. ";./service/?.lua;"
local skynet = require("skynet")
local service = require("skynet.service")
local mgr = require("chat_server.manager")
require("skynet.manager")
require("common.export")
require("service_config.type")

local CMD = {
	servicetype = SERVICE_TYPE.CHAT.ID, 	-- 服务类型
	servername = SERVICE_TYPE.CHAT.NAME,  	-- 服务名
}

function CMD.START()
	math.randomseed(os.time())

	mgr.start(CMD.servername)

    return 0
end

function CMD.STOP() 
    mgr.stop()
    return 0
end

-- 登录服·消息处理接口
function CMD.MESSAGE(head, content)
    assert(head ~= nil and type(head)== "table")
    assert(content ~= nil and type(content)== "table")
	return mgr.dispatch(head, content)
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
