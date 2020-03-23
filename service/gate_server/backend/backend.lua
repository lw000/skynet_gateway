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

local CMD = {
    name = "backend",
    scheme = "ws",
    debug = false,
    running = false,
    serverId = 0,
    aliveTime = 100*5,
    gate_server = -1,
    client = ws:new()
}

function CMD.START(scheme, host, content)
    CMD.scheme = scheme
    CMD.host = host
    CMD.debug = content.debug
    CMD.gate_server = content.gate_server

    CMD.client:handleMessage(CMD.message)
    CMD.client:handleError(CMD.error)
    local ok, err = CMD.client:connect(scheme, host)
    if err then
        return 1, err
    end

    CMD.running = true

    CMD.name = string.format("%s.%d", CMD.name, skynet.self())

    -- 注册服务
    CMD.registerService()

    -- 网络断线检查
    skynet.timeout(CMD.aliveTime, CMD.alive)
    
    return 0
end

function CMD.STOP()

end

function CMD.SERVICE_MESSAGE(head, content)
    -- dump(head, CMD.name .. ".head")
    -- dump(content, CMD.name .. ".content")
    skynet.fork(function (head, content)
        CMD.client:sendWithClientId(head.mid, head.sid, head.clientId, content.data)
    end, head, content)
end

function CMD.registerService()
    local content = functor.pack_ReqRegService(
        {
            serverId = CMD.serverId,
            svrType = SERVICE_TYPE.GATE.ID
        }
    )
    CMD.client:send(CENTER_CMD.MDM, CENTER_CMD.SUB.REGIST, content, function(pk)
        local data = functor.unpack_AckRegService(pk:data())
        dump(data, "AckRegistService")
        if data.result == 0 then
            -- skynet.error("code=" .. data.result, "serverId=" .. data.serverId, "errmsg=" .. data.errmsg)
        end
    end)
end

-- 网络状态是否存活
function CMD.alive()
    if CMD.running then
        skynet.timeout(CMD.aliveTime, CMD.alive)
    end

    local open = CMD.client:open()
    if not open then
        skynet.error("reconnect to server")
        local ok, err = CMD.client:connect(CMD.scheme, CMD.host)
        if err ~= nil then
            skynet.error(ok, err)
        else
            CMD.registerService()
        end 
    end
end

function CMD.message(pk)
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

    if CMD.debug then
        skynet.error(CMD.name .. " message", "mid=" .. mid, "sid=" .. sid, "checkCode=" .. checkCode, "clientId=" .. clientId, "len=" .. string.len(pk:data()))
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
        if CMD.debug then
            -- dump(head, CMD.name .. ".head")
            -- dump(content, CMD.name .. ".content")
        end  
        skyhelper.send(clientId, "service_message", head, content)
    end
    skynet.fork(forwardMessage, clientId, head, content)
end

function CMD.error(err)
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
            local f = CMD[cmd]
            assert(f)
            if f then
                skynet.ret(skynet.pack(f(...)))
            else
                skynet.error(string.format("unknown CMD %s", tostring(cmd)))
            end
        end
    )
    skynet.register(".backend")
end

skynet.start(dispatch)
