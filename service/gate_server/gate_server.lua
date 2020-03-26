package.path = package.path .. ";./service/?.lua;"
local skynet = require("skynet")
local socket = require("skynet.socket")
local service = require("skynet.service")
local skyhelper = require("skycommon.helper")
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
    agents = {},
}

function CMD.start(content)
    CMD.debug = content.debug
    CMD.port = content.port
    CMD.centerPort = content.centerPort
    CMD.centerIP = content.centerIP,
    assert(CMD.port > 0)

    local host = string.format("%s:%d", CMD.centerIP, CMD.centerPort)
    for i=1, 10 do
        local center_proxy = skynet.newservice("proxy/center_proxy", skynet.self())
        skynet.call(center_proxy, "lua", "start", "ws", host, {
            debug = content.debug,
        })
        center_proxy_servers[i] = center_proxy
    end
    -- dump(center_proxy_servers, "center_proxy_servers")

    CMD.listen()
    
    return 0
end

function CMD.stop()
    socket.close(CMD.fd)
end

function CMD.listen()
    local fd = socket.listen("0.0.0.0", CMD.port)
    assert(fd ~= -1, "listen fail")

    skynet.error(string.format("listen port:" .. CMD.port))
    
    socket.start(fd, function(id, addr)
        local agent = skynet.newservice("gate_agent", skynet.self())
        CMD.agents[agent] = agent
        local index = (agent % #center_proxy_servers)+1
        
        -- skynet.error("center_proxy_server index:", index)

        local center_proxy_server_id = center_proxy_servers[index]
        skynet.send(agent, "lua", "accept", id, CMD.protocol, addr, {
            debug = CMD.debug,
            center_proxy_server_id = center_proxy_server_id,
        })
    end)
end

function CMD.query_agent(agent)
    local clientAgent = CMD.agents[agent]
    return clientAgent
end

function CMD.register_agent(agent)
    CMD.agents[agent] = agent
end

function CMD.kick_agent(agent)
    CMD.agents[agent] = nil
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
