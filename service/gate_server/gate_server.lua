package.path = package.path .. ";./service/?.lua;"
local skynet = require("skynet")
local socket = require("skynet.socket")
local service = require("skynet.service")
require("skynet.manager")
require("service_config.type")

local command = {
    servertype = SERVICE_TYPE.GATE.ID,
    servername = SERVICE_TYPE.GATE.NAME,
    debug = false,
    port = 8080,
    centerPort = 8081,
    centerIP = "127.0.0.1",
    protocol = "ws",
    -- agents = {},
    sockt_listen_id = -1,
    backend_servers = {},        -- 后端转发服务ID
}

function command.START(content)
    command.debug = content.debug
    command.port = content.port
    command.centerPort = content.centerPort
    command.centerIP = content.centerIP,
    assert(command.port > 0)

    local host = string.format("%s:%d", command.centerIP, command.centerPort)
    for i= 0, 5 do
        local backend_server = skynet.newservice("backend")
        command.backend_servers[i] = backend_server
        skynet.call(backend_server, "lua", "start", "ws", host, {
            debug = content.debug,
            gate_server = skynet.self(),
        })
    end
    command.listen()
    return 0
end

function command.STOP()
    backend.stop()
    socket.close(command.sockt_listen_id)
end

function command.listen()
    command.sockt_listen_id = socket.listen("0.0.0.0", command.port)
    assert(command.sockt_listen_id ~= -1, "listen fail")

    skynet.error(string.format("listen port:" .. command.port))
    
    socket.start(command.sockt_listen_id, function(id, addr)
        local agent = skynet.newservice("gate_agent")
        -- command.agents[agent] = agent
        -- dump(command.backend_servers, "command.backend_servers")
        local backend_server_length = #command.backend_servers+1
        local backendIndex = math.fmod(agent, backend_server_length)
        local backend_server = command.backend_servers[backendIndex]
        -- skynet.error(
        --     "agent=", agent,
        --     "backend_server_length=", backend_server_length,
        --     "backendIndex=", backendIndex,
        --     "backend_server=", backend_server
        -- )
        skynet.send(agent, "lua", "start", id, command.protocol, addr, {
            debug = command.debug,
            backend_server = backend_server,
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
