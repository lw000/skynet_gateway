package.path = package.path .. ";./service/?.lua;"
local skynet = require("skynet")
local socket = require("skynet.socket")
local service = require("skynet.service")
require("skynet.manager")
require("service_config.type")

local command = {
    servertype = SERVICE_TYPE.GATE.ID,
    servername = SERVICE_TYPE.GATE.NAME,
    sfd = 0,
    port = 8080,
    protocol = "ws",
    agents = {},
    center_server = 0,
}

function command.START(conf)
    command.port = conf.port
    command.center_server = conf.center_server

    command.listen()

    skynet.error(command.servername .. " start")
    return 0
end

function command.STOP()
    socket.close(command.sfd)

    skynet.error(command.servername .. " stop")
end

function command.listen()
    command.sfd = socket.listen("0.0.0.0", command.port)
    assert(command.sfd ~= 0, "listen fail")

    skynet.error(string.format("listen websocket port: " .. command.port))

    socket.start(command.sfd, function(id, addr)
        local agent = skynet.newservice("agent")
        command.agents[agent] = agent
        skynet.send(agent, "lua", "start", id, command.protocol, addr, command.center_server)
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
