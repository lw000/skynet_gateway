local skynet = require("skynet")
local service = require("skynet.service")
local ws = require("wsext")
local timer = require("timer")
local hub = require("hub")
local packet = require("packet")
local skyhelper = require("helper")
local utils = require("utils")
require("skynet.manager")
require("service_cmd")
require("service_type")
require("proto_func")

local gate = ...

local handler = {
    servername = ".center_proxy",
    scheme = "ws",
    debug = false,
    serverId = 0,
    tick_s = 5,
    keepalive_s = 3,
    client = ws:new()
}

function handler.start(scheme, host, content)
    handler.scheme = scheme
    handler.host = host
    handler.debug = content.debug

    handler.client:handleMessage(handler.message)
    handler.client:handleError(handler.error)
    local ok, err = handler.client:connect(scheme, host)
    if err then
        return 1, err
    end

    -- 心跳处理
    timer.runEvery(handler.tick_s, handler.tick)

    -- 网络断线检查
    timer.runEvery(handler.keepalive_s, handler.keepalive)

    -- 注册服务
    handler.registerService()

    return 0
end

function handler.stop()

end

-- 心跳检查
function handler.tick()
    if handler.client:open() then
        handler.send(0x0000, 0x0000, nil, nil)
    end
end

-- 连接检查
function handler.keepalive()
    local open = handler.client:open()
    if not open then
        skynet.error("attempting reconnect in " .. tonumber(handler.keepalive_s) .." seconds")
        local ok, err = handler.client:connect(handler.scheme, handler.host)
        if err ~= nil then
            skynet.error(ok, err)
        end
        open = handler.client:open()
        if open then
            handler.registerService()
        end
    end
end

function handler.send_center_message(content)
    if handler.debug then
        utils.dump(content, handler.servername .. ".content")
    end
    handler.sendWithClientId(content.mid, content.sid, content.clientId, content.data)
end

function handler.registerService()
    local content = functor.pack_ReqRegService(
        {
            serverId = handler.serverId,
            svrType = SERVICE_TYPE.GATE.ID
        }
    )
    handler.send(CENTER_CMD.MDM, CENTER_CMD.SUB.REGIST, content, function(content)
        local data = functor.unpack_AckRegService(content)
        -- utils.dump(data, "AckRegistService")
        if data.result == 0 then
            handler.serverId = data.serverId
            skynet.error("center_proxy registered serverId=" .. data.serverId)
        end
    end)
end

function handler.sendBuff(data)
    handler.client:send(data)
end

function handler.sendWithClientId(mid, sid, clientId, data, fn)
    if not handler.client:open() then
        skynet.error("network is disconnect")
        return
    end

    local pk = packet:new()
    pk:pack(mid, sid, clientId, data)
    if pk:data() == nil then
        skynet.error("create packet error")
        return
    end

    if fn then
        hub.register(mid, sid, fn)
    end

    local ok, ret = pcall(handler.sendBuff, pk:data())
    if not ok then
        skynet.error(ret)
    end
end

function handler.send(mid, sid, data, fn)
    return handler.sendWithClientId(mid, sid, 0, data, fn)
end

function handler.message(msg)
    local pk = packet:new()
    pk:unpack(msg)

    local mid = pk:mid()
    local sid = pk:sid()

    -- 代理服务内部消息分发
    if hub.dispatchMessage(mid, sid, pk:data()) then
        return
    end

    -- 转发到客户端gate_agent服务
    local clientId = pk:clientId()
    local content = {
        data = msg
    }

    local ok, agent = pcall(skyhelper.call, gate, "query_agent", clientId)
    if ok and agent ~= nil then
        local ok, ret = pcall(skyhelper.send, agent, "send_client_message", content)
        if not ok then
            skynet.error(ret)
        end
    end
end

function handler.error(err)
    skynet.error(err)
end

skynet.init(
    function()
        skynet.register(handler.servername)
    end
)

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
end

skynet.start(dispatch)
