package.path = package.path .. ";./service/?.lua;"
local skynet = require("skynet")
local websocket = require("http.websocket")
local packet = require("network.packet")
local skyhelper = require("skycommon.helper")
require("skynet.manager")
require("service_config.type")
require("proto_map.proto_map")

local handle = {
    name = "gate_server.agent",
    debug = false,
    sock_id = -1,
    gate_server = -1,
    backend_server = -1,
}

function handle.START(sock_id, protocol, addr, content)
    -- dump(content, "content")
    handle.debug = content.debug
    handle.gate_server = content.gate_server
    handle.backend_server = content.backend_server

    handle.name = string.format("%s.%d", handle.name, skynet.self())

    local ok, err = websocket.accept(sock_id, handle, protocol, addr)
    if err then
        skynet.error(err)
        return 1, "websocket.accept fail"
    end
    
    return 0
end

function handle.STOP()

end

function handle.SERVICE_MESSAGE(head, content)
    -- dump(head, handle.name .. ".head")
    handle.send(handle.sock_id, head.mid, head.sid, head.clientId, content.data)
end

function handle.connect(sock_id)
    handle.sock_id = sock_id
    -- skynet.error("ws connect from: " .. tostring(sock_id))
end

function handle.handshake(sock_id, header, url)
    local addr = websocket.addrinfo(sock_id)
    -- skynet.error("ws handshake from", "addr=" .. addr, "url=" .. url)
    
    -- skynet.error("----header-----")
    -- for k, v in pairs(header) do
    --     skynet.error(k, v)
    -- end
    -- skynet.error("--------------")
end

function handle.message(sock_id, msg)
    local pk = packet:new()
    pk:unpack(msg)

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

    if handle.debug then
        skynet.error(handle.name .. " message", "mid=" .. mid, "sid=" .. sid, "checkCode=" .. checkCode, "clientId=" .. clientId, "len=" .. string.len(pk:data()))
    end

    -- 心跳消息处理
    if mid == 0 and sid == 0 then
        return
    end

    -- 包头
    local head = {
        mid = pk:mid(),
        sid = pk:sid(),
        clientId = skynet.self(),
    }

    -- 包体内容
    local content = {
        data = pk:data()
    }

    local forwardMessage = function(sock_id, head, content)   
        -- dump(head, handle.name .. ".head")
        -- dump(content, handle.name .. ".content")
        skyhelper.send(handle.backend_server, "service_message", head, content)
    end
    skynet.fork(forwardMessage, sock_id, head, content)
end

function handle.ping(sock_id)
    skynet.error("ws ping from: " .. tostring(sock_id) .. "\n")
end

function handle.pong(sock_id)
    skynet.error("ws pong from: " .. tostring(sock_id))
end

function handle.close(sock_id, code, reason)
    skynet.error("ws close from: " .. tostring(sock_id), code, reason)
    skynet.exit()
end

function handle.error(sock_id)
    skynet.error("ws error from: " .. tostring(sock_id))
    skynet.exit()
end

function handle.send(sock_id, mid, sid, clientid, content)
    local pk = packet:new()
    pk:pack(mid, sid, clientid, content)
    websocket.write(sock_id, pk:data(), "binary", 0x02)
end

-- skynet.init(
--     function()
--         skynet.error("agent init")
--     end
-- )

local function dispatch()
    -- skynet.dispatch(
    --     "lua",
    --     function(session, address, sock_id, protocol, addr, center_server)
    --         handle.center_server = center_server
    --         -- skynet.error("accept sock_id=" .. sock_id .. " addr=" .. skynet.address(address) .. " addr=" .. addr)
    --         skynet.error("accept sock_id=" .. sock_id .. " addr=" .. addr)
    --         local ok, err = websocket.accept(sock_id, handle, protocol, addr)
    --         if err then
    --             skynet.error(err)
    --         end
    --     end
    -- )

    skynet.dispatch(
        "lua",
        function(session, address, cmd, ...)
            cmd = cmd:upper()
            local f = handle[cmd]
            assert(f)
            if f then
                skynet.ret(skynet.pack(f(...)))
            else
                skynet.error(string.format(handle.name .. " unknown command %s", tostring(cmd)))
            end
        end
    )
    skynet.register(".gate_agent")
end

skynet.start(dispatch)
