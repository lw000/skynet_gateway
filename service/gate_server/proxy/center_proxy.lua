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

local gate_server_id = -1

local CMD = {
    servername = ".center_proxy",
    scheme = "ws",
    debug = false,
    running = false,
    serverId = 0,
    aliveTime = 2,
    client = ws:new()
}

function CMD.start(scheme, host, content)
    CMD.scheme = scheme
    CMD.host = host
    CMD.debug = content.debug
    gate_server_id = content.gate_server_id

    CMD.client:handleMessage(CMD.on_message)
    CMD.client:handleError(CMD.on_error)
    local ok, err = CMD.client:connect(scheme, host)
    if err then
        return 1, err
    end

    CMD.running = true

    -- 网络断线检查
    skynet.timeout(CMD.aliveTime, CMD.alive)
    
    -- 心跳处理
    timer.start(30, function()
        if CMD.client:open() then
            CMD.send(0x0000, 0x0000, 0, nil)
        end
    end)

    -- 网络断线检查
    timer.start(CMD.aliveTime, function()
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

function CMD.service_message(head, content)
    if CMD.debug then
        dump(head, CMD.servername .. ".head")
        dump(content, CMD.servername .. ".content")
    end

    skynet.fork(function (head, content)
        CMD.sendWithClientId(head.mid, head.sid, head.clientId, content)
    end, head, content)
end

function CMD.registerService()
    local content = functor.pack_ReqRegService(
        {
            serverId = CMD.serverId,
            svrType = SERVICE_TYPE.GATE.ID
        }
    )
    CMD.send(CENTER_CMD.MDM, CENTER_CMD.SUB.REGIST, 0, content, function(pk)
        local data = functor.unpack_AckRegService(pk:data())
        dump(data, "AckRegistService")
        if data.result == 0 then
            -- skynet.error("code=" .. data.result, "serverId=" .. data.serverId, "errmsg=" .. data.errmsg)
        end
    end)
end

function CMD.sendWithClientId(mid, sid, clientId, content)
    local pk = packet:new()
    pk:pack(mid, sid, clientId, content.data)
    CMD.client:send(pk:data())
end

function CMD.send(mid, sid, clientId, content, fn)
    if not CMD.client:open() then
        skynet.error("network is disconnect")
        return
    end
 
    local pk = packet:new()
    pk:pack(mid, sid, clientId, content)
    if pk:data() == nil then
        skynet.error("create packet error")
        return
    end
    hub.register(mid, sid, fn)
    CMD.client:send(pk:data())
end

function CMD.on_message(msg)
    local pk = packet:new()
    pk:unpack(msg)

    local clientId = pk:clientId()

    local content = {
        data = msg
    }

    local forwardMessage = function(clientId, content)
        if CMD.debug then
            -- dump(head, CMD.servername .. ".head")
            -- dump(content, CMD.servername .. ".content")
        end  
        skyhelper.send(clientId, "service_message", nil, content)
    end
    skynet.fork(forwardMessage, clientId, content)
end

-- function CMD.on_message(pk)
--     local mid = pk:mid()
--     local sid = pk:sid()
--     local ver = pk:ver()
--     local checkCode = pk:checkCode()
--     local clientId = pk:clientId()

--     -- 检查版本
--     if ver >= 0 then
--         -- body
--     end

--     -- 包校验码检查
--     if checkCode ~= 123456 then
--         -- body
--     end

--     if CMD.debug then
--         skynet.error(CMD.servername .. " message", "mid=" .. mid, "sid=" .. sid, "checkCode=" .. checkCode, "clientId=" .. clientId, "len=" .. string.len(pk:data()))
--     end

--     -- 包头
--     local head = {
--         mid = mid,
--         sid = sid,
--         ver = ver,
--         checkCode = checkCode,
--         clientId = clientId,
--     }

--     -- 内容
--     local content = {
--         data = pk:data()
--     }

--     local forwardMessage = function(clientId, head, content)
--         if CMD.debug then
--             -- dump(head, CMD.servername .. ".head")
--             -- dump(content, CMD.servername .. ".content")
--         end  
--         skyhelper.send(clientId, "service_message", head, content)
--     end
--     skynet.fork(forwardMessage, clientId, head, content)
-- end

function CMD.on_error(err)
    skynet.error(err)
end

-- skynet.init(
--     function()
--         skynet.error("ws_client init ......")
--     end
-- )

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
