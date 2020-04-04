local skynet = require("skynet")
local socket = require("skynet.socket")
local service = require("skynet.service")
local cluster = require("skynet.cluster")
local skyhelper = require("skycommon.helper")
require("skynet.manager")
require("service_type")

local center_proxy_servers = {}  -- 后端代理服务ID
local master_proxy

local CMD = {
    servertype = SERVICE_TYPE.GATE.ID,
    servername = SERVICE_TYPE.GATE.NAME,
    debug = false,
    agents = {},
}

function CMD.start(config)
    assert(config ~= nil)
    assert(config.port > 0)

    CMD.debug = config.debug

    local master = skynet.newservice("proxy/master_proxy")
    skynet.call(master, "lua", "open", 1)
        
    local host = string.format("%s:%d", config.centerIP, config.centerPort)
    for i=1, 10 do
        local center_proxy = skynet.newservice("proxy/center_proxy", skynet.self())
        skynet.call(center_proxy, "lua", "start", "ws", host, {
            debug = config.debug,
        })
        center_proxy_servers[i] = center_proxy
    end
    -- dump(center_proxy_servers, "center_proxy_servers")

    -- master_proxy = cluster.proxy("db", "@master_service")

    -- -- cluster.reload {
    -- --     db = "127.0.0.1:2528",
    -- --     db2 = "127.0.0.1:2529"
    -- -- }

    -- skynet.fork(function ( ... )
    --     skynet.error(pcall(skynet.call, master_proxy, "GET", "a"))
    --     skynet.error(cluster.call("db", "@master_service", "GET", "b"))
    -- end)

    CMD.listen(config.port)
    
    return 0
end

function CMD.stop()

end

function CMD.listen(port)
    local fd = socket.listen("0.0.0.0", port)
    assert(fd ~= -1, "listen fail")

    skynet.error(string.format("listen port:" .. port))
    local protocol = "ws"
    socket.start(fd, function(id, addr)
        local agent = skynet.newservice("gate_agent", skynet.self())
        CMD.agents[agent] = agent
        local index = (agent % #center_proxy_servers)+1 
        local center_proxy_server_id = center_proxy_servers[index]
        skynet.send(agent, "lua", "accept", id, protocol, addr, {
            debug = CMD.debug,
            center_proxy_server_id = center_proxy_server_id,
        })
    end)
end

function CMD.query_agent(agent)
    return CMD.agents[agent]
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
