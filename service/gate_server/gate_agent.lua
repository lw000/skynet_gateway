package.path = package.path .. ";./service/?.lua;"
local skynet = require("skynet")
local websocket = require("http.websocket")
local packet = require("network.packet")
local skyhelper = require("skycommon.helper")
require("skynet.manager")
require("service_config.type")
require("proto_map.proto_map")

local gate_server_id = -1

local center_proxy_server_id = -1

local handle = {
    servername = ".gate_agent",
    debug = false,
    sock_id = -1,
}

function handle.start(sock_id, protocol, addr, content)
    -- dump(content, "content")
    handle.debug = content.debug
    gate_server_id = content.gate_server_id
    center_proxy_server_id = content.center_proxy_server_id

    local ok, err = websocket.accept(sock_id, handle, protocol, addr)
    if err then
        skynet.error(err)
        return 1, "websocket.accept fail"
    end
    
    return 0
end

function handle.stop()

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
        skynet.error(handle.servername .. " message", "mid=" .. mid, "sid=" .. sid, "checkCode=" .. checkCode, "clientId=" .. clientId, "len=" .. string.len(pk:data()))
    end

    -- 心跳消息处理
    if mid == 0 and sid == 0 then
        --处理客户端心跳，超时的关闭
        -- skynet.error("心跳", os.date("%Y-%m-%d %H:%M:%S", os.time()))
        return
    end

    -- 包内容
    local content = {
        mid = mid,
        sid = sid,
        clientId = skynet.self(),
        data = pk:data()
    }

    if handle.debug then
        dump(content, handle.servername .. ".content")
    end

    skyhelper.send(center_proxy_server_id, "send_center_message", content)
end

function handle.ping(sock_id)
    -- skynet.error("ws ping from: " .. tostring(sock_id) .. "\n")
end

function handle.pong(sock_id)
    -- skynet.error("ws pong from: " .. tostring(sock_id))
end

function handle.close(sock_id, code, reason)
    -- skynet.error("ws close from: " .. tostring(sock_id), code, reason)
    skynet.exit()
end

function handle.error(sock_id)
    -- skynet.error("ws error from: " .. tostring(sock_id))
    skynet.exit()
end

function handle.send_client_message(content)
    if handle.debug then
        dump(content, handle.servername .. ".content")
    end
    handle.send(handle.sock_id, content.data)
end

function handle.send(sock_id, data)
    local ok = pcall(websocket.write, sock_id, data, "binary", 0x02)
    if not ok then
        skynet.error("websocket.write error")
    end
end

skynet.init(
    function()
        skynet.register(handle.servername)
    end
)

local function dispatch()
    skynet.dispatch(
        "lua",
        function(session, address, cmd, ...)
            local f = handle[cmd]
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
