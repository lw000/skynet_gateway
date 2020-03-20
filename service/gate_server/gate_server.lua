package.path = package.path .. ";./service/?.lua;"
local skynet = require("skynet")
local socket = require("skynet.socket")
local service = require("skynet.service")
require("skynet.manager")
require("service_config.define")

local command = {
    servertype = SERVICE_CONF.GATE.TYPE,
    servername = SERVICE_CONF.GATE.NAME,
    sfd = 0,
    port = 8080,
    protocol = "ws",
    agents = {}
}

function command.START(port)
    command.port = port
    command.run()

    skynet.error("gate_server start")
    return 0
end

function command.STOP()
    socket.close(command.sfd)
    skynet.error("gate_server exit")
end

function command.run()
    command.sfd = socket.listen("0.0.0.0", command.port)
    assert(command.sfd ~= 0, "listten fail")

    skynet.error(string.format("listen websocket port: " .. command.port))

    socket.start(command.sfd, function(id, addr)
        local agent = skynet.newservice("agent")
        command.agents[agent] = agent
        skynet.send(agent, "lua", id, command.protocol, addr)
    end)
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
                    skynet.error(string.format("unknown command %s", tostring(cmd)))
                end
            end
        )
    skynet.register("gate_server")
end

skynet.start(dispatch)
