local skynet = require("skynet")
local socket = require("skynet.socket")
local service = require("skynet.service")
local cluster = require("skynet.cluster")
local skyhelper = require("skycommon.helper")
local utils = require("utils")
require("skynet.manager")
require("service_type")

local master_proxy

local center_proxy_servers = {}  -- 后端代理服务ID

local agents = {}

local handler = {
    servertype = SERVICE_TYPE.GATE.ID,
    servername = SERVICE_TYPE.GATE.NAME,
    debug = false,
    
}

function handler.start(config)
    assert(config ~= nil)
    assert(config.port > 0)

    handler.debug = config.debug

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
    -- utils.dump(center_proxy_servers, "center_proxy_servers")

    handler.listen(config.port)
    
    return 0
end

function handler.stop()
    skynet.exit()

    return 0
end

function handler.listen(port)
    local fd = socket.listen("0.0.0.0", port)
    assert(fd ~= -1, "gate listen fail")

    skynet.error(string.format("listen port:" .. port))
    local protocol = "ws"
    socket.start(fd, function(id, addr)
        local agent = skynet.newservice("agent", skynet.self())
        agents[agent] = agent
        local index = (agent % #center_proxy_servers)+1 
        local center_proxy_server_id = center_proxy_servers[index]
        skynet.send(agent, "lua", "accept", id, protocol, addr, {
            debug = handler.debug,
            center_proxy_server_id = center_proxy_server_id,
        })
    end)
end

function handler.query_agent(agent)
    return agents[agent]
end

function handler.kick_agent(agent)
    agents[agent] = nil
end

local function dispatch()
    skynet.dispatch(
        "lua",
        function(session, address, cmd, ...)
            local f = handler[cmd]
            assert(f)
            if session == 0 then
                f(...)
            else
                skynet.ret(skynet.pack(f(...)))
            end
        end
    )
    skynet.register(handler.servername)
end

skynet.start(dispatch)
