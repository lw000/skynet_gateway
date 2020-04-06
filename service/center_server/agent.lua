local skynet = require("skynet")
local websocket = require("http.websocket")
local packet = require("packet")
local backendRoute = require("center_server.center_route")
local skyhelper = require("skycommon.helper")
local logger = require("logger")
local utils = require("utils")
require("skynet.manager")
require("service_config.service_type")
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
end

function handler.send_client_message(head, data)
    if handler.debug then
        utils.dump(head, handler.servername .. ".head")
    end
    handler.send(handler.fd, head, data)
end

function handler.connect(fd)
    handler.fd = fd
    -- skynet.error("ws connect from: " .. tostring(fd))
end

function handler.handshake(fd, header, url)
    local addr = websocket.addrinfo(fd)
    -- logger.debug("ws handshake from add=%s url=%s", addr, url)
    
    -- logger.debug("----header-----")
    -- for k, v in pairs(header) do
    --     skynet.error(k, v)
    -- end
    -- logger.debug("-----end-----")
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
        -- skynet.error(handler.servername .. " message", "mid=" .. mid, "sid=" .. sid, "checkCode=" .. checkCode, "clientId=" .. clientId, "len=" .. string.len(pk:data()))
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
        ver = ver,
        checkCode = checkCode,
        clientId = clientId,
        agent = skynet.self(),
    }

    -- 内容
    local content = {
        data = pk:data()
    }

    -- 转发消息
    local service = backendRoute[head.mid]
    if service == nil then
        local errmsg = "unknown " .. handler.servername .. " mid=" .. tostring(head.mid) .. " command" 
        skynet.error(errmsg)
        return
    end

    skyhelper.send(service.name, "dispatch_send_message", head, content)
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

function handler.send(fd, head, data)
    local pk = packet:new()
    pk:pack(head.mid, head.sid, head.clientId, data)
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
