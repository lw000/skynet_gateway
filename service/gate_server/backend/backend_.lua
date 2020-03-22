package.path = package.path .. ";./service/?.lua;"
local skynet = require("skynet")
local service = require("skynet.service")
local ws = require("network.ws")
require("skynet.manager")
require("common.export")
require("service_config.cmd")
require("service_config.type")
require("proto_map.proto_func")
local skyhelper = require("skycommon.helper")

local backend = {
    name = "backend",
    scheme = "ws",
    debug = false,
    running = false,
    serverId = 0,
    gate_server = -1,
    client = ws:new()
}

function backend.start(scheme, host, content)
    backend.scheme = scheme
    backend.host = host
    backend.debug = content.debug
    backend.gate_server = content.gate_server

    backend.client:handleMessage(backend.message)
    backend.client:handleError(backend.error)
    local ok, err = backend.client:connect(scheme, host)
    if err then
        return 1, err
    end

    backend.running = true

    backend.name = string.format("%s.%d", backend.name, skynet.self())

    -- 注册服务
    backend.registerService()

    -- 网络断线检查
    backend.alive()
    
    return 0
end

function backend.stop()

end

function backend.sfd()
    return backend.client:sfd()
end

function backend.SERVICE_MESSAGE(head, content)
    -- dump(head, backend.name .. ".head")
    -- dump(content, backend.name .. ".content")
    -- backend.client:sendWithClientId(head.mid, head.sid, head.clientId, content.data)

end

function backend.send(head, content)
    skynet.fork(function (head, content)
        backend.client:sendWithClientId(head.mid, head.sid, head.clientId, content.data)
    end, head, content)
end

function backend.registerService()
    local content = functor.pack_ReqRegService(
        {
            serverId = backend.serverId,
            svrType = SERVICE_TYPE.GATE.ID
        }
    )
    backend.client:registerService(CENTER_CMD.MDM, CENTER_CMD.SUB.REGIST, content, function(pk)
        local data = functor.unpack_AckRegService(pk:data())
        dump(data, "AckRegistService")
        if data.result == 0 then
            -- skynet.error("code=" .. data.result, "serverId=" .. data.serverId, "errmsg=" .. data.errmsg)
        end
    end)
end

-- 网络状态是否存活
function backend.alive()
    local on_alive = function()
        while backend.running do
            local open = backend.client:open()
            if not open then
                skynet.error("reconnect to server")
                backend.client:connect(backend.scheme, backend.host)
                backend.registerService()
            end
            skynet.sleep(100 * 5)
        end
    end

    local on_error = function(err)
        skynet.error(err)
    end

    skynet.fork(function()
        local ok = xpcall(on_alive, on_error)
        if not ok then
            -- body
        end
        skynet.error("alive exit")
    end)
end

function backend.message(pk)
    local mid = pk:mid()
    local sid = pk:sid()
    local ver = pk:ver()
    local checkCode = pk:checkCode()
    local clientId = pk:clientId()

    -- 检查版本
    if ver >= 0 then
        -- body
    end

    -- 包校验码检查
    if checkCode ~= 123456 then
        -- body
    end

    -- if backend.debug then
        skynet.error(backend.name .. " message", "mid=" .. mid, "sid=" .. sid, "checkCode=" .. checkCode, "clientId=" .. clientId, "len=" .. string.len(pk:data()))
    -- end

    -- 包头
    local head = {
        mid = mid,
        sid = sid,
        ver = ver,
        checkCode = checkCode,
        clientId = clientId,
    }

    -- 内容
    local content = {
        data = pk:data()
    }

    local forwardMessage = function(clientId, head, content)   
        -- dump(head, backend.name .. ".head")
        skyhelper.send(clientId, "service_message", head, content)
    end
    skynet.fork(forwardMessage, clientId, head, content)
end

function backend.error(err)
    skynet.error(err)
end

return backend