package.path = package.path .. ";./service/?.lua;"
local skynet = require("skynet")
local socket = require("skynet.socket")
local service = require("skynet.service")
require("skynet.manager")
require("service_config.type")

local command = {
    servertype = SERVICE_TYPE.GATE.ID,
    servername = SERVICE_TYPE.GATE.NAME,
    port = 8080,
    centerPort = 8081,
    protocol = "ws",
    -- agents = {},
    sockt_listen_id = -1,
    backend = -1,        -- 后端转发服务ID
}

function command.START(content)
    command.port = content.port
    command.centerPort = content.centerPort,
    assert(command.port > 0)

    command.backend = skynet.newservice("backend")
    local host = string.format("%s:%d", "127.0.0.1", command.centerPort)
    skynet.call(command.backend, "lua", "start", "ws", host, {
        gate_server = skynet.self(),
    })
    
    command.listen()

    return 0
end

function command.STOP()
    socket.close(command.sockt_listen_id)
end

function command.listen()
    command.sockt_listen_id = socket.listen("0.0.0.0", command.port)
    assert(command.sockt_listen_id ~= -1, "listen fail")

    skynet.error(string.format("listen port:" .. command.port))
    
    socket.start(command.sockt_listen_id, function(id, addr)
        local agent = skynet.newservice("gate_agent")
        -- command.agents[agent] = agent
        skynet.send(agent, "lua", "start", id, command.protocol, addr, {
            backend = command.backend,    
            gate_server = skynet.self(),
        })
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
                skynet.error(string.format(command.servername .. " unknown command %s", tostring(cmd)))
            end
        end
    )
    skynet.register("gate_server")
end

skynet.start(dispatch)
