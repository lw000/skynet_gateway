package.path = package.path .. ";./service/?.lua;"
local skynet = require("skynet")
local socket = require("skynet.socket")
local service = require("skynet.service")
local skyhelper = require("skycommon.helper")
require("skynet.manager")
require("service_config.type")

local CMD = {
    servertype = SERVICE_TYPE.CENTER.ID,
    servername = SERVICE_TYPE.CENTER.NAME,
    debug = false,
    port = 8081,
    protocol = "ws",
    -- agents = {},
    sockt_listen_id = -1,
}

function CMD.start(content)
    CMD.debug = content.debug
    CMD.port = content.port
    assert(CMD.port > 0)

    CMD.listen()
    return 0
end

function CMD.stop()
    socket.close(CMD.sockt_listen_id)
end

function CMD.listen()
    CMD.sockt_listen_id = socket.listen("0.0.0.0", CMD.port)
    assert(CMD.sockt_listen_id ~= -1, "listen fail")

    skynet.error(string.format("listen port:" .. CMD.port))
    
    socket.start(CMD.sockt_listen_id, function(id, addr)
        local agent = skynet.newservice("service/center_agent", skynet.self())
        skynet.send(agent, "lua", "start", id, CMD.protocol, addr, {
            debug = CMD.debug,
        })
    end)
end

function CMD.service_message(head, content)
    assert(head ~= nil and type(head)== "table")
    if CMD.debug then
        dump(head, CMD.servername .. ".head")
    end
    skyhelper.send(head.serviceId, "service_message", head, content)
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
