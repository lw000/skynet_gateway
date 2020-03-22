package.path = package.path .. ";./service/?.lua;"
local skynet = require("skynet")
local socket = require("skynet.socket")
local service = require("skynet.service")
local skyhelper = require("skycommon.helper")
-- local mgr = require("center_server.manager")
require("skynet.manager")
require("service_config.type")

local command = {
    servertype = SERVICE_TYPE.CENTER.ID,
    servername = SERVICE_TYPE.CENTER.NAME,
    port = 8081,
    protocol = "ws",
    -- agents = {},
    sockt_listen_id = -1,
}

function command.START(content)
    command.port = content.port
    assert(command.port > 0)

    -- mgr.start(command.servername)
    
    command.listen()
    return 0
end

function command.STOP()
    -- mgr.stop()
    socket.close(command.sockt_listen_id)
end

function command.listen()
    command.sockt_listen_id = socket.listen("0.0.0.0", command.port)
    assert(command.sockt_listen_id ~= -1, "listen fail")

    skynet.error(string.format("listen port:" .. command.port))
    
    socket.start(command.sockt_listen_id, function(id, addr)
        local agent = skynet.newservice("center_agent")
        skynet.send(agent, "lua", "start", id, command.protocol, addr, {
            servername = command.servername,
            center_server = skynet.self(),
        })
    end)
end

-- function command.MESSAGE(head, content)
--     assert(head ~= nil and type(head)== "table")
--     assert(content ~= nil and type(content)== "table")
-- 	return mgr.dispatch(head, content)
-- end

function command.ON_CORE_MESSAGE(head, content)
    assert(head ~= nil and type(head)== "table")
    -- dump(head, command.servername .. ".head")
    skyhelper.send(head.serviceId, "on_message", head, content)
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
