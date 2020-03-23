package.path = package.path .. ";./service/?.lua;"
local skynet = require("skynet")
local socket = require("skynet.socket")
local service = require("skynet.service")
require("skynet.manager")
require("service_config.type")

local CMD = {
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

function CMD.START(content)
    CMD.debug = content.debug
    CMD.port = content.port
    CMD.centerPort = content.centerPort
    CMD.centerIP = content.centerIP,
    assert(CMD.port > 0)

    local host = string.format("%s:%d", CMD.centerIP, CMD.centerPort)
    for i= 0, 5 do
        local backend_server = skynet.newservice("backend")
        CMD.backend_servers[i] = backend_server
        skynet.call(backend_server, "lua", "start", "ws", host, {
            debug = content.debug,
            gate_server = skynet.self(),
        })
    end
    CMD.listen()
    return 0
end

function CMD.STOP()
    backend.stop()
    socket.close(CMD.sockt_listen_id)
end

function CMD.listen()
    CMD.sockt_listen_id = socket.listen("0.0.0.0", CMD.port)
    assert(CMD.sockt_listen_id ~= -1, "listen fail")

    skynet.error(string.format("listen port:" .. CMD.port))
    
    socket.start(CMD.sockt_listen_id, function(id, addr)
        local agent = skynet.newservice("gate_agent")
        -- CMD.agents[agent] = agent
        -- dump(CMD.backend_servers, "CMD.backend_servers")
        local backend_server_length = #CMD.backend_servers+1
        local backendIndex = math.fmod(agent, backend_server_length)
        local backend_server = CMD.backend_servers[backendIndex]
        -- skynet.error(
        --     "agent=", agent,
        --     "backend_server_length=", backend_server_length,
        --     "backendIndex=", backendIndex,
        --     "backend_server=", backend_server
        -- )
        skynet.send(agent, "lua", "start", id, CMD.protocol, addr, {
            debug = CMD.debug,
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
            local f = CMD[cmd]
            assert(f)
            if f then
                skynet.ret(skynet.pack(f(...)))
            else
                skynet.error(string.format(CMD.servername .. " unknown CMD %s", tostring(cmd)))
            end
        end
    )
    skynet.register("gate_server")
end

skynet.start(dispatch)
