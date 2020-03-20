package.path = package.path .. ";./service/?.lua;"
local skynet = require("skynet")
local socket = require("skynet.socket")
local service = require("skynet.service")
local centermgr = require("center_server.manager")
require("skynet.manager")
require("core.define")

local command = {
    servertype = SERVICE_CONF.CENTER.TYPE,
    servername = SERVICE_CONF.CENTER.NAME, 
}

function command.START(port)
    command.port = port

    centermgr.start(command.servername)

    skynet.error("center_server start")

    return 0
end

function command.STOP()
    centermgr.stop()
    skynet.error("center_server exit")
end

function command.MESSAGE(mid, sid, content)
    skynet.error(string.format(command.servername .. ":> mid=%d sid=%d", mid, sid))
	return centermgr.dispatch(mid, sid, content)
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
