package.path = package.path .. ";./service/?.lua;"
local skynet = require("skynet")
local socket = require("skynet.socket")
local service = require("skynet.service")
require("skynet.manager")
require("service_config.type")

local center_proxy_servers = {}  -- 后端代理服务ID

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
}

function CMD.start(content)
    CMD.debug = content.debug
    CMD.port = content.port
    CMD.centerPort = content.centerPort
    CMD.centerIP = content.centerIP,
    assert(CMD.port > 0)

    local host = string.format("%s:%d", CMD.centerIP, CMD.centerPort)
    for i=0, 9 do
        local center_proxy = skynet.newservice("proxy/center_proxy")
        center_proxy_servers[i] = center_proxy
        skynet.call(center_proxy, "lua", "start", "ws", host, {
            debug = content.debug,
            gate_server_id = skynet.self(),
        })
    end
    -- dump(center_proxy_servers, "center_proxy_servers")

    CMD.listen()
    
    return 0
end

function CMD.stop()
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
        local center_proxy_server_length = #center_proxy_servers+1
        local index = agent % center_proxy_server_length
        local center_proxy_server_id = center_proxy_servers[index]
        -- skynet.error(
        --     "agent=", agent,
        --     "index=", index,
        --     "center_proxy_server_id=", center_proxy_server_id
        -- )
        skynet.send(agent, "lua", "start", id, CMD.protocol, addr, {
            debug = CMD.debug,
            center_proxy_server_id = center_proxy_server_id,
            gate_server = skynet.self(),
        })
    end)
end

local function dispatch()
    skynet.dispatch(
        "lua",
        function(session, address, cmd, ...)
            local f = CMD[cmd]
            assert(f)
            if session == 0 then
                f(...)
            else
                skynet.ret(skynet.pack(f(...)))
            end
        end
    )
    skynet.register(CMD.servername)
end

skynet.start(dispatch)
