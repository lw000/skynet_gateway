local skynet = require("skynet")
local service = require("skynet.service")
local ws = require("wsext")
local timer = require("timer")
local hub = require("hub")
local packet = require("packet")
local utils = require("utils")
require("skynet.manager")
require("service_type")
require("proto_map")
require("proto_func")

local handler = {
    scheme = "ws",
    host = "127.0.0.1",
    tick_s = 5,
    keepalive_s = 3,
    client = ws:new()
}

function handler.start(scheme, host, content)
    handler.account = content.account
    handler.password = content.password
    handler.scheme = scheme
    handler.host = host
    handler.client:handleMessage(handler.message)
    handler.client:handleError(handler.error)
    local ok, err = handler.client:connect(scheme, host)
    if err then
        return 1, "connect fail"
    end

    -- 心跳
    timer.runEvery(handler.tick_s, handler.tick)

    -- 连接检查
    timer.runEvery(handler.keepalive_s, handler.keepalive)

    -- 注册账号，登录账号
    skynet.fork(handler.regist)

    return 0
end

function handler.stop()
    timer.stop()
end

-- 心跳
function handler.tick()
    if handler.client:open() then
        handler.send(0x0000, 0x0000, nil, nil)
        -- handler.client:ping()
    end
end

-- 连接检查
function handler.keepalive()
    local open = handler.client:open()
    if not open then
        skynet.error("reconnect to server")
        local ok, err = handler.client:connect(handler.scheme, handler.host)
        if err ~= nil then
            skynet.error(ok, err)
        end
        open = handler.client:open()
        if open then
            handler.regist()
        end
    end
end

-- 注册账号
function handler.regist()
    local reqLogin = functor.pack_ReqRegist(
    {
        account = handler.account,
        password = handler.password,
    })

    handler.send(LOBBY_CMD.MDM, LOBBY_CMD.SUB.REGIST, reqLogin, function(msg)
        local data = functor.unpack_AckRegist(msg)
        utils.dump(data, "AckRegist")

        handler.logon()
    end)
end

-- 登录账号
function handler.logon()
    local reqLogin = functor.pack_ReqLogin(
    {
        account = handler.account,
        password = handler.password,
    })

    handler.send(LOBBY_CMD.MDM, LOBBY_CMD.SUB.LOGON, reqLogin, function(msg)
        local data = functor.unpack_AckLogin(msg)
        utils.dump(data, "AckLogin")
        
        -- 测试发送消息
        skynet.fork(handler.chat, data.userInfo.userId)
    end)
end

function handler.chat(userId)
    while handler.client:open() do
        local chatMessage = functor.pack_ChatMessage(
        {
            from = userId,
            to = 11,
            content = "hello" .. userId
        })
        handler.send(CHAT_CMD.MDM, CHAT_CMD.SUB.CHAT, chatMessage, function(msg)
            local data = functor.unpack_AckChatMessage(msg)
            utils.dump(data, "AckChatMessage")
        end)
        skynet.sleep(100)
    end
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

    handler.sendBuff(pk:data())
end

function handler.send(mid, sid, data, fn)
    return handler.sendWithClientId(mid, sid, 0, data, fn)
end

function handler.message(msg)
    local pk = packet:new()
    pk:unpack(msg)
    local mid = pk:mid()
    local sid = pk:sid()
    hub.dispatchMessage(mid, sid, pk:data())
end

function handler.error(err)
    skynet.error(err)
end

skynet.init(
    function()
        skynet.register(".robot_server")
    end
)

local function dispatch()
    skynet.dispatch(
        "lua",
        function(session, address, cmd, ...)
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
