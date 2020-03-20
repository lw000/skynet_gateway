package.path = package.path .. ";./service/?.lua;"
local skynet = require("skynet")
local service = require("skynet.service")
local ws = require("network.ws")
require("skynet.manager")
require("common.export")
require("service_config.define")
require("proto_map.proto_map")
require("proto_map.sp")

local command = {
    scheme = "ws",
    host = "127.0.0.1",
    running = false,
    client = ws:new()
}

local msgs_switch = {
    [0x0001] = {
        name = "MDM_CORE",
        [0x0001] = {
            name = "SUB_CORE_REGISTER",
            fn = function(conn, pk)
                local data = proto_map.decode_AckRegistService(pk:data())
                dump(data, "AckRegistService")
                if data.result == 0 then
                end
            end
        }
    }
}

function command.START(scheme, host)
    command.scheme = scheme
    command.host = host
    command.client:handleMessage(command.message)
    command.client:handleError(command.error)
    local ok, err = command.client:connect(scheme, host)
    if err then
        return 1, "connect fail"
    end
    command.running = true

    -- 网络断线检查
    command.alive()

    skynet.fork(command.test)
    
    return 0
end

function command.test()
    while (command.running) do
        local reqLogin = functor.encode_ReqLogin(
        {
            account = "levi",
            password = "123456",
        })
        
        command.client:send(LOGON_CMD.MDM_LOGON, LOGON_CMD.SUB.LOGON, reqLogin, function(conn, pk)
            local data = functor.decode_AckLogin(pk:data())
            dump(data, "AckLogin")
        end)
        local chatMessage = functor.encode_ChatMessage(
            {
                from = 10,
                to = 11,
                content = "hello"
            })
            command.client:send(LOGON_CMD.MDM_LOGON, LOGON_CMD.SUB.CHAT, chatMessage, function(conn, pk)
                local data = functor.decode_AckChatMessage(pk:data())
                dump(data, "AckChatMessage")
            end)

        skynet.sleep(100)

    end
end

function command.alive()
    local on_alive = function()
        while command.running do
            local open = command.client:open()
            if not open then
                skynet.error("reconnect to server")
                command.client:connect(command.scheme, command.host)
            end
            skynet.sleep(100 * 3)
        end
    end

    local on_error = function(err)
        skynet.error(err)
    end

    skynet.fork(
        function()
            local ok = xpcall(on_alive, on_error)
            if not ok then
                -- body
            end
            skynet.error("alive exit")
        end
    )
end

function command.message(conn, pk)
    local mid = pk:mid()
    local sid = pk:sid()
    local msgmap = msgs_switch[mid][sid]
    if msgmap then
        if msgmap.fn ~= nil then
            skynet.fork(msgmap.fn, self, pk)
        -- msgmap.fn(self, pk)
        end
    else
        skynet.error("<: pk", "mid=" .. pk:mid() .. ", sid=" .. pk:sid() .. "命令未实现")
    end
end

function command.error(err)
    skynet.error(err)
end

skynet.init(
    function()
        skynet.error("ws_client init")
    end
)

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
    skynet.register(".ws_client")
end

skynet.start(dispatch)
