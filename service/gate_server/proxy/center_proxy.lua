package.path = package.path .. ";./service/?.lua;"
local skynet = require("skynet")
local service = require("skynet.service")
local ws = require("network.wsext")
local timer = require("network.timer")
local hub = require("network.hub")
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
    running = false,
    serverId = 0,
    keepalive = 2,
    client = ws:new()
}

function CMD.start(scheme, host, content)
    CMD.scheme = scheme
    CMD.host = host
    CMD.debug = content.debug

    CMD.client:handleMessage(CMD.on_message)
    CMD.client:handleError(CMD.on_error)
    local ok, err = CMD.client:connect(scheme, host)
    if err then
        return 1, err
    end

    CMD.running = true

    -- 心跳处理
    timer.start(30, function()
        if CMD.client:open() then
            CMD.send(0x0000, 0x0000, 0, nil, nil)
        end
    end)

    -- 网络断线检查
    timer.start(CMD.keepalive, function()
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
    end)

    -- 注册服务
    CMD.registerService()

    return 0
end

function CMD.stop()

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
        dump(data, "AckRegistService")
        if data.result == 0 then
            -- skynet.error("code=" .. data.result, "serverId=" .. data.serverId, "errmsg=" .. data.errmsg)
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

function CMD.on_message(msg)
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
    local ok, ret = pcall(skyhelper.send, clientId, "send_client_message", content)
    if not ok then
        skynet.error(ret)
    end
end

function CMD.on_error(err)
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
