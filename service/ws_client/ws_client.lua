package.path = package.path .. ";./service/?.lua;"
local skynet = require("skynet")
local service = require("skynet.service")
local ws = require("network.ws")
require("skynet.manager")
require("common.export")
require("service_config.type")
require("proto_map.proto_map")
require("proto_map.proto_func")

local CMD = {
    scheme = "ws",
    host = "127.0.0.1",
    running = false,
    aliveTime = 100*5,
    client = ws:new()
}

local msgs_switch = {
    [0x0001] = {
        name = "MDM_CORE",
        [0x0001] = {
            name = "SUB_CORE_REGISTER",
            fn = function(pk)
                local data = functor.decode_AckRegistService(pk:data())
                dump(data, "AckRegistService")
                if data.result == 0 then
                end
            end
        }
    }
}

function CMD.START(scheme, host, content)
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
    CMD.running = true

    -- 网络断线检查
    -- CMD.alive()
    skynet.timeout(CMD.aliveTime, CMD.alive)

    CMD.regist()

    return 0
end

-- 注册账号
function CMD.regist()
    local reqLogin = functor.pack_ReqRegist(
    {
        account = CMD.account,
        password = CMD.password,
    })

    CMD.client:send(LOBBY_CMD.MDM, LOBBY_CMD.SUB.REGIST, reqLogin, function(pk)
        local data = functor.unpack_AckRegist(pk:data())
        -- dump(data, "AckRegist")
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

    CMD.client:send(LOBBY_CMD.MDM, LOBBY_CMD.SUB.LOGON, reqLogin, function(pk)
        local data = functor.unpack_AckLogin(pk:data())
        -- dump(data, "AckLogin")
        
        -- 测试发送消息
        skynet.fork(CMD.test, data.userInfo.userId)
    end)
end

function CMD.test(userId)
    while (CMD.running) do
        local chatMessage = functor.pack_ChatMessage(
        {
            from = userId,
            to = 11,
            content = "hello"
        })
        CMD.client:send(CHAT_CMD.MDM, CHAT_CMD.SUB.CHAT, chatMessage, function(pk)
            local data = functor.unpack_AckChatMessage(pk:data())
            -- dump(data, "AckChatMessage")
        end)

        skynet.sleep(100)
    end
end

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

    -- local on_alive = function()
    --     while CMD.running do
    --         local open = CMD.client:open()
    --         if not open then
    --             skynet.error("reconnect to server")
    --             local ok, err = CMD.client:connect(CMD.scheme, CMD.host)
    --             if err then
    --                 skynet.error(ok, err)
    --             end
    --         end
    --         skynet.sleep(100 * 3)
    --     end
    -- end

    -- local on_error = function(err)
    --     skynet.error(err)
    -- end

    -- skynet.fork(
    --     function()
    --         local ok = xpcall(on_alive, on_error)
    --         if not ok then
    --             -- body
    --         end
    --         skynet.error("alive exit")
    --     end
    -- )
end

function CMD.message(pk)
    local mid = pk:mid()
    local sid = pk:sid()
    local msgmap = msgs_switch[mid][sid]
    if msgmap then
        if msgmap.fn ~= nil then
            skynet.fork(msgmap.fn, pk)
        end
    else
        skynet.error("<: pk", "mid=" .. mid .. ", sid=" .. sid .. "命令未实现")
    end
end

function CMD.error(err)
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
    skynet.register(".ws_client")
end

skynet.start(dispatch)
