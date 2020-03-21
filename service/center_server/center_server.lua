package.path = package.path .. ";./service/?.lua;"
local skynet = require("skynet")
local socket = require("skynet.socket")
local service = require("skynet.service")
local skyhelper = require("skycommon.helper")
local centermgr = require("center_server.manager")
require("skynet.manager")
require("service_config.type")

local command = {
    servertype = SERVICE_TYPE.CENTER.ID,
    servername = SERVICE_TYPE.CENTER.NAME,
    logon_server = 0,
}

function command.START(conf)
    command.logon_server = conf.logon_server

    centermgr.start(command.servername)
    return 0
end

function command.STOP()
    centermgr.stop()
end

function command.MESSAGE(head, content)
    assert(head ~= nil and type(head)== "table")
    assert(content ~= nil and type(content)== "table")
	return centermgr.dispatch(head, content)
end

function command.ON_MESSAGE(head, content)
    assert(head ~= nil and type(head)== "table")
    skyhelper.send(head.clientId, "on_message", head, content)
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
