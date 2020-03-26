package.path = package.path .. ";./service/?.lua;"
local skynet = require("skynet")
local service = require("skynet.service")
local ws = require("network.wsext")
local timer = require("sharelib.timer")
local hub = require("sharelib.hub")
local packet = require("network.packet")
local skyhelper = require("skycommon.helper")
require("skynet.manager")
require("common.export")
require("service_config.cmd")
require("service_config.type")
require("proto_map.proto_func")

local gate = ...

local CMD = {
    servername = ".center_proxy",
    scheme = "ws",
    debug = false,
    serverId = 0,
    tick_s = 5,
    keepalive_s = 3,
    client = ws:new()
}

function CMD.start(scheme, host, content)
    CMD.scheme = scheme
    CMD.host = host
    CMD.debug = content.debug

    CMD.client:handleMessage(CMD.message)
    CMD.client:handleError(CMD.error)
    local ok, err = CMD.client:connect(scheme, host)
    if err then
        return 1, err
    end

    -- 心跳处理
    timer.runEvery(CMD.tick_s, CMD.tick)

    -- 网络断线检查
    timer.runEvery(CMD.keepalive_s, CMD.keepalive)

    -- 注册服务
    CMD.registerService()

    return 0
end

function CMD.stop()

end

-- 心跳检查
function CMD.tick()
    if CMD.client:open() then
        CMD.send(0x0000, 0x0000, 0, nil, nil)
        -- CMD.client:ping()
    end
end

-- 连接检查
function CMD.keepalive()
    local open = CMD.client:open()
    if not open then
        skynet.error("reconnect to server")
        local ok, err = CMD.client:connect(CMD.scheme, CMD.host)
        if err ~= nil then
            skynet.error(ok, err)  
        end
        open = CMD.client:open()
        if open then
            CMD.registerService()
        end
    end
end

function CMD.send_center_message(content)
    if CMD.debug then
        dump(content, CMD.servername .. ".content")
    end
    CMD.sendWithClientId(content.mid, content.sid, content.clientId, content.data)
end

function CMD.registerService()
    local content = functor.pack_ReqRegService(
        {
            serverId = CMD.serverId,
            svrType = SERVICE_TYPE.GATE.ID
        }
    )
    CMD.send(CENTER_CMD.MDM, CENTER_CMD.SUB.REGIST, content, function(content)
        local data = functor.unpack_AckRegService(content)
        -- dump(data, "AckRegistService")
        if data.result == 0 then
            skynet.error("center_proxy registered serverId=" .. data.serverId)
        end
    end)
end

function CMD.sendBuff(data)
    CMD.client:send(data)
end

function CMD.sendWithClientId(mid, sid, clientId, data, fn)
    if not CMD.client:open() then
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

    local ok, ret = pcall(CMD.sendBuff, pk:data())
    if not ok then
        skynet.error(ret)
    end
end

function CMD.send(mid, sid, data, fn)
    return CMD.sendWithClientId(mid, sid, 0, data, fn)
end

function CMD.message(msg)
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

function CMD.error(err)
    skynet.error(err)
end

skynet.init(
    function()
        skynet.register(CMD.servername)
    end
)

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
end

skynet.start(dispatch)
