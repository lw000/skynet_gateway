package.path = package.path .. ";./service/?.lua;"
local skynet = require("skynet")
local websocket = require("http.websocket")
local packet = require("network.packet")
local skyhelper = require("skycommon.helper")
require("skynet.manager")
require("service_config.type")
require("proto_map.proto_map")

local gate = ...

local handler = {
    servername = ".gate_agent",
    debug = false,
    fd = -1,
    center_proxy_server_id = -1
}

function handler.accept(fd, protocol, addr, content)
    -- dump(content, "content")
    handler.debug = content.debug
    handler.center_proxy_server_id = content.center_proxy_server_id

    local ok, err = websocket.accept(fd, handler, protocol, addr)
    if err then
        skynet.error(err)
        return 1, "websocket.accept fail"
    end
    
    return 0
end

function handler.connect(fd)
    handler.fd = fd
    -- skynet.error("ws connect from: " .. tostring(fd))
end

function handler.handshake(fd, header, url)
    local addr = websocket.addrinfo(fd)
    -- skynet.error("ws handshake from", "addr=" .. addr, "url=" .. url)
    
    -- skynet.error("----header-----")
    -- for k, v in pairs(header) do
    --     skynet.error(k, v)
    -- end
    -- skynet.error("--------------")
end

function handler.message(fd, msg)
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

    if handler.debug then
        skynet.error(handler.servername .. " message", "mid=" .. mid, "sid=" .. sid, "checkCode=" .. checkCode, "clientId=" .. clientId, "len=" .. string.len(pk:data()))
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

    if handler.debug then
        dump(content, handler.servername .. ".content")
    end

    skyhelper.send(handler.center_proxy_server_id, "send_center_message", content)
end

function handler.ping(fd)
    -- skynet.error("ws ping from: " .. tostring(fd) .. "\n")
end

function handler.pong(fd)
    -- skynet.error("ws pong from: " .. tostring(fd))
end

function handler.close(fd, code, reason)
    -- skynet.error("ws close from: " .. tostring(fd), code, reason)
    skynet.exit()
end

function handler.error(fd)
    -- skynet.error("ws error from: " .. tostring(fd))
    skynet.exit()
end

function handler.send_client_message(content)
    if handler.debug then
        dump(content, handler.servername .. ".content")
    end
    handler.send(handler.fd, content.data)
end

function handler.send(fd, data)
    local ok = pcall(websocket.write, fd, data, "binary", 0x02)
    if not ok then
        skynet.error("websocket.write error")
    end
end

skynet.init(
    function()
        skynet.register(handler.servername)
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
