package.path = package.path .. ";./service/?.lua;"
local skynet = require("skynet")
local service = require("skynet.service")
local ws = require("network.wsext")
local timer = require("network.timer")
local hub = require("network.hub")
local packet = require("network.packet")
require("skynet.manager")
require("common.export")
require("service_config.type")
require("proto_map.proto_map")
require("proto_map.proto_func")

local CMD = {
    scheme = "ws",
    host = "127.0.0.1",
    running = false,
    aliveTime = 2,
    client = ws:new()
}

function CMD.start(scheme, host, content)
    CMD.account = content.account
    CMD.password = content.password
    CMD.scheme = scheme
    CMD.host = host
    CMD.client:handleMessage(CMD.on_message)
    CMD.client:handleError(CMD.on_error)
    local ok, err = CMD.client:connect(scheme, host)
    if err then
        return 1, "connect fail"
    end

    CMD.running = true

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
                CMD.regist()
            end
        end
    end)

    CMD.regist()

    return 0
end

function CMD.stop()
    CMD.running = false
    timer.stop()
end

-- 注册账号
function CMD.regist()
    local reqLogin = functor.pack_ReqRegist(
    {
        account = CMD.account,
        password = CMD.password,
    })

    CMD.send(LOBBY_CMD.MDM, LOBBY_CMD.SUB.REGIST, 0, reqLogin, function(msg)
        local data = functor.unpack_AckRegist(msg)
        dump(data, "AckRegist")

        CMD.logon()
    end)
end

-- 登录账号
function CMD.logon()
    local reqLogin = functor.pack_ReqLogin(
    {
        account = CMD.account,
        password = CMD.password,
    })

    CMD.send(LOBBY_CMD.MDM, LOBBY_CMD.SUB.LOGON, 0, reqLogin, function(msg)
        local data = functor.unpack_AckLogin(msg)
        dump(data, "AckLogin")
        
        -- 测试发送消息
        skynet.fork(CMD.test, data.userInfo.userId)
    end)
end

function CMD.test(userId)
    while (CMD.running) do
        if CMD.client:open() then
            local chatMessage = functor.pack_ChatMessage(
            {
                from = userId,
                to = 11,
                content = "hello"
            })
            CMD.send(CHAT_CMD.MDM, CHAT_CMD.SUB.CHAT, 0, chatMessage, function(msg)
                local data = functor.unpack_AckChatMessage(msg)
                dump(data, "AckChatMessage")
            end)
        end

        skynet.sleep(100)
    end
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
    local mid = pk:mid()
    local sid = pk:sid()
    hub.dispatchMessage(mid, sid, pk:data())
end

function CMD.on_error(err)
    skynet.error(err)
end

-- skynet.init(
--     function()
--         skynet.error("ws_client init")
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
    skynet.register(".ws_client")
end

skynet.start(dispatch)
