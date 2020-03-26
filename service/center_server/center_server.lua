package.path = package.path .. ";./service/?.lua;"
local skynet = require("skynet")
local socket = require("skynet.socket")
local service = require("skynet.service")
local logic = require("center_server.center_logic")
local skyhelper = require("skycommon.helper")
require("skynet.manager")
require("service_config.type")
require("proto_map.proto_map")

-- 业务处理接口映射表
local methods = {
    [CENTER_CMD.SUB.REGIST] = {func=logic.onRegist, desc="服务注册"},
    [CENTER_CMD.SUB.UNREGIST] = {func=logic.onUnregist, desc="服务卸载"}
}

local CMD = {
    servertype = SERVICE_TYPE.CENTER.ID,
    servername = SERVICE_TYPE.CENTER.NAME,
    debug = false,
    port = 8081,
    protocol = "ws",
}

function CMD.start(content)
    CMD.debug = content.debug
    CMD.port = content.port
    assert(CMD.port > 0)

    CMD.listen()

    return 0
end

function CMD.stop()

end

function CMD.listen()
    local fd = socket.listen("0.0.0.0", CMD.port)

    skynet.error(string.format("ws listen port:" .. CMD.port))
    
    socket.start(fd, function(id, addr)
        local agent = skynet.newservice("service/center_agent", skynet.self())
        skynet.send(agent, "lua", "accept", id, CMD.protocol, addr, {
            debug = CMD.debug,
        })
    end)
end

function CMD.dispatch_send_message(head, content)
    if CMD.debug then
        dump(head, CMD.servername .. ".head")
    end

    local method = methods[head.sid]
    assert(method ~= nil)
    if method == nil then
        local errmsg = "unknown " .. CMD.servername .. " [sid=" .. tostring(head.sid) .. "] command"
        skynet.error(errmsg)
        return nil, errmsg
    end

    local ret, ack = proto_map.exec(head, content, method.func)
    if ret ~= 0 then
        skynet.error(ret, ack)
        return ack 
    end

    skyhelper.send(head.center_agent, "send_client_message", head, ack)
end

function CMD.register_service(head, content)

end

function CMD.unregister_service(head, content)

end

local function dispatch()
    skynet.dispatch(
        "lua",
        function(session, address, cmd, ...)
            -- skynet.error(CMD.servername .. " recved:",session, address, cmd, ...)
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
