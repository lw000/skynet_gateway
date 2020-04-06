local skynet = require("skynet")
local socket = require("skynet.socket")
local service = require("skynet.service")
local cluster = require("skynet.cluster")
local logic = require("center_logic")
local skyhelper = require("skycommon.helper")
local utils = require("utils")
require("skynet.manager")
require("service_config.service_type")
require("proto_map.proto_map")

-- 业务处理接口映射表
local methods = {
    [CENTER_CMD.SUB.REGIST] = {func=logic.onRegist, desc="服务注册"},
    [CENTER_CMD.SUB.UNREGIST] = {func=logic.onUnregist, desc="服务卸载"}
}

local handler = {
    servertype = SERVICE_TYPE.CENTER.ID,
    servername = SERVICE_TYPE.CENTER.NAME,
    debug = false,
    protocol = "ws",
}

function handler.start(content)
    handler.debug = content.debug
    handler.port = content.port
    assert(handler.port > 0)

    handler.listen(content.port)

    return 0
end

function handler.stop()

end

function handler.listen(port)
    local fd = socket.listen("0.0.0.0", port)

    skynet.error(string.format("ws listen port:" .. port))
    
    socket.start(fd, function(id, addr)
        local agent = skynet.newservice("service/center_agent", skynet.self())
        skynet.send(agent, "lua", "accept", id, handler.protocol, addr, {
            debug = handler.debug,
        })
    end)
end

function handler.dispatch_send_message(head, content)
    if handler.debug then
        utils.dump(head, handler.servername .. ".head")
    end

    local method = methods[head.sid]
    assert(method ~= nil)
    if method == nil then
        local errmsg = "unknown " .. handler.servername .. " [sid=" .. tostring(head.sid) .. "] command"
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

function handler.register_service(head, content)

end

function handler.unregister_service(head, content)

end

local function dispatch()
    skynet.dispatch(
        "lua",
        function(session, address, cmd, ...)
            -- skynet.error(handler.servername .. " recved:",session, address, cmd, ...)
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
