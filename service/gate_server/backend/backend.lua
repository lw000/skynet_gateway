package.path = package.path .. ";./service/?.lua;"
local skynet = require("skynet")
local service = require("skynet.service")
local ws = require("network.ws")
local skyhelper = require("skycommon.helper")
require("skynet.manager")
require("common.export")
require("service_config.cmd")
require("service_config.type")
require("proto_map.proto_func")

local command = {
    name = "backend",
    scheme = "ws",
    debug = false,
    running = false,
    serverId = 0,
    gate_server = -1,
    client = ws:new()
}

function command.START(scheme, host, content)
    command.scheme = scheme
    command.host = host
    command.debug = content.debug
    command.gate_server = content.gate_server

    command.client:handleMessage(command.message)
    command.client:handleError(command.error)
    local ok, err = command.client:connect(scheme, host)
    if err then
        return 1, err
    end

    command.running = true

    command.name = string.format("%s.%d", command.name, skynet.self())

    -- 注册服务
    command.registerService()

    -- 网络断线检查
    command.alive()
    
    return 0
end

function command.STOP()

end

function command.SERVICE_MESSAGE(head, content)
    -- dump(head, command.name .. ".head")
    -- dump(content, command.name .. ".content")
    -- command.client:sendWithClientId(head.mid, head.sid, head.clientId, content.data)
    skynet.fork(function (head, content)
        command.client:sendWithClientId(head.mid, head.sid, head.clientId, content.data)
    end, head, content)
end

function command.registerService()
    local content = functor.pack_ReqRegService(
        {
            serverId = command.serverId,
            svrType = SERVICE_TYPE.GATE.ID
        }
    )
    command.client:registerService(CENTER_CMD.MDM, CENTER_CMD.SUB.REGIST, content, function(pk)
        local data = functor.unpack_AckRegService(pk:data())
        dump(data, "AckRegistService")
        if data.result == 0 then
            -- skynet.error("code=" .. data.result, "serverId=" .. data.serverId, "errmsg=" .. data.errmsg)
        end
    end)
end

-- 网络状态是否存活
function command.alive()
    local on_alive = function()
        while command.running do
            local open = command.client:open()
            if not open then
                skynet.error("reconnect to server")
                command.client:connect(command.scheme, command.host)
                command.registerService()
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

function command.message(pk)
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

    if command.debug then
        skynet.error(command.name .. " message", "mid=" .. mid, "sid=" .. sid, "checkCode=" .. checkCode, "clientId=" .. clientId, "len=" .. string.len(pk:data()))
    end

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
        if command.debug then
            -- dump(head, command.name .. ".head")
            -- dump(content, command.name .. ".content")
        end  
        skyhelper.send(clientId, "service_message", head, content)
    end
    skynet.fork(forwardMessage, clientId, head, content)
end

function command.error(err)
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
            cmd = cmd:upper()
            local f = command[cmd]
            assert(f)
            if f then
                skynet.ret(skynet.pack(f(...)))
            else
                skynet.error(string.format("unknown command %s", tostring(cmd)))
            end
        end
    )
    skynet.register(".backend")
end

skynet.start(dispatch)
