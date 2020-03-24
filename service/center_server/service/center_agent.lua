package.path = package.path .. ";./service/?.lua;"
local skynet = require("skynet")
local websocket = require("http.websocket")
local packet = require("network.packet")
local mgr = require("center_server.service.center_manager")
local skyhelper = require("skycommon.helper")
require("skynet.manager")
require("service_config.type")
require("proto_map.proto_map")

local center = ...

local handler = {
    servername = ".center_agent",
    debug = false,
    fd = -1,
}

function handler.accept(fd, protocol, addr, content)
    handler.debug = content.debug

    local ok, err = websocket.accept(fd, handler, protocol, addr)
    if err then
        skynet.error(err)
        return 1, "websocket.accept fail"
    end

    mgr.start(handler.servername, handler.debug)
end

function handler.service_message(head, content)
    if handler.debug then
        dump(head, handler.servername .. ".head")
        dump(content, handler.servername .. ".content")
    end
    handler.send(handler.fd, head, content)
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
        -- skynet.error("心跳", "mid=" .. ssmid, "sid=" .. sid, os.date("%Y-%m-%d %H:%M:%S", os.time()))
        return
    end

    -- 包头
    local head = {
        mid = pk:mid(),
        sid = pk:sid(),
        clientId = clientId,
        serviceId = skynet.self(),
    }

    -- 内容
    local content = {
        data = pk:data()
    }

    if handler.debug then
        -- dump(head, handler.servername .. ".head")
        -- dump(content, handler.servername .. ".content")
    end

    -- 消息分发
    mgr.dispatch(head, content)
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

function handler.send(fd, head, content)
    local pk = packet:new()
    pk:pack(head.mid, head.sid, head.clientId, content)
    local ok = pcall(websocket.write, fd, pk:data(), "binary", 0x02)
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
    -- skynet.dispatch(
    --     "lua",
    --     function(session, address, fd, protocol, addr, center_server)
    --         handler.center_server = center_server
    --         -- skynet.error("accept fd=" .. fd .. " addr=" .. skynet.address(address) .. " addr=" .. addr)
    --         skynet.error("accept fd=" .. fd .. " addr=" .. addr)
    --         local ok, err = websocket.accept(fd, handler, protocol, addr)
    --         if err then
    --             skynet.error(err)
    --         end
    --     end
    -- )

    skynet.dispatch(
        "lua",
        function(session, address, cmd, ...)
            -- skynet.error(handler.servername .. " recved:", session, address, cmd, ...)
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
