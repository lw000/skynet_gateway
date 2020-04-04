local skynet = require("skynet")
local service = require("skynet.service")
local ws = require("wsext")
local timer = require("timer")
local hub = require("hub")
local packet = require("packet")
require("skynet.manager")
require("utils")
require("service_type")
require("proto_map")
require("proto_func")

local CMD = {
    scheme = "ws",
    host = "127.0.0.1",
    tick_s = 5,
    keepalive_s = 3,
    client = ws:new()
}

function CMD.start(scheme, host, content)
    CMD.account = content.account
    CMD.password = content.password
    CMD.scheme = scheme
    CMD.host = host
    CMD.client:handleMessage(CMD.message)
    CMD.client:handleError(CMD.error)
    local ok, err = CMD.client:connect(scheme, host)
    if err then
        return 1, "connect fail"
    end

    -- 心跳
    timer.runEvery(CMD.tick_s, CMD.tick)

    -- 连接检查
    timer.runEvery(CMD.keepalive_s, CMD.keepalive)

    -- 注册账号，登录账号
    skynet.fork(CMD.regist)

    return 0
end

function CMD.stop()
    timer.stop()
end

-- 心跳
function CMD.tick()
    if CMD.client:open() then
        CMD.send(0x0000, 0x0000, nil, nil)
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
            CMD.regist()
        end
    end
end

-- 注册账号
function CMD.regist()
    local reqLogin = functor.pack_ReqRegist(
    {
        account = CMD.account,
        password = CMD.password,
    })

    CMD.send(LOBBY_CMD.MDM, LOBBY_CMD.SUB.REGIST, reqLogin, function(msg)
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

    CMD.send(LOBBY_CMD.MDM, LOBBY_CMD.SUB.LOGON, reqLogin, function(msg)
        local data = functor.unpack_AckLogin(msg)
        dump(data, "AckLogin")
        
        -- 测试发送消息
        skynet.fork(CMD.chat, data.userInfo.userId)
    end)
end

function CMD.chat(userId)
    while CMD.client:open() do
        local chatMessage = functor.pack_ChatMessage(
        {
            from = userId,
            to = 11,
            content = "hello" .. userId
        })
        CMD.send(CHAT_CMD.MDM, CHAT_CMD.SUB.CHAT, chatMessage, function(msg)
            local data = functor.unpack_AckChatMessage(msg)
            -- dump(data, "AckChatMessage")
        end)
        skynet.sleep(100)
    end
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

    CMD.sendBuff(pk:data())
end

function CMD.send(mid, sid, data, fn)
    return CMD.sendWithClientId(mid, sid, 0, data, fn)
end

function CMD.message(msg)
    local pk = packet:new()
    pk:unpack(msg)
    local mid = pk:mid()
    local sid = pk:sid()
    hub.dispatchMessage(mid, sid, pk:data())
end

function CMD.error(err)
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
