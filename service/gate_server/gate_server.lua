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
    protocol = "ws",
    -- agents = {},
    sockt_listen_id = -1,
    -- center_server_id = -1,
    -- gate_server_id = -1,
}

function command.START(content)
    command.port = content.port
    command.center_server_id = content.center_server_id
    command.gate_server_id = skynet.self()
    assert(command.port > 0)
    assert(command.center_server_id ~= -1)
    assert(command.gate_server_id ~= -1)

    command.listen()

    return 0
end

function command.STOP()
    socket.close(command.sockt_listen_id)
end

function command.listen()
    command.sockt_listen_id = socket.listen("0.0.0.0", command.port)
    assert(command.sockt_listen_id ~= -1, "listen fail")

    skynet.error(string.format("ws listen port:" .. command.port))
    
    socket.start(command.sockt_listen_id, function(id, addr)
        local agent = skynet.newservice("agent")
        -- command.agents[agent] = agent
        skynet.send(agent, "lua", "start", id, command.protocol, addr, {
            -- center_server_id = command.center_server_id,
            -- gate_server_id = command.gate_server_id
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
