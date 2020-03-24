package.path = package.path .. ";./service/?.lua;"
local skynet = require("skynet")
local websocket = require("http.websocket")
local packet = require("network.packet")
local mgr = require("center_server.service.center_manager")
local skyhelper = require("skycommon.helper")
require("skynet.manager")
require("service_config.type")
require("proto_map.proto_map")

local center_server_id = -1

local handle = {
    servername = ".center_agent",
    debug = false,
    sock_id = -1,
}

function handle.start(sock_id, protocol, addr, content)
    handle.debug = content.debug
    center_server_id = content.center_server_id

    local ok, err = websocket.accept(sock_id, handle, protocol, addr)
    if err then
        skynet.error(err)
        return 1, "websocket.accept fail"
    end

    mgr.start(handle.servername, handle.debug)

    return 0
end

function handle.stop()
    mgr.stop()
end

function handle.service_message(head, content)
    if handle.debug then
        dump(head, handle.servername .. ".head")
        dump(content, handle.servername .. ".content")
    end
    handle.send(handle.sock_id, head, content)
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

    if handle.debug then
        -- dump(head, handle.servername .. ".head")
        -- dump(content, handle.servername .. ".content")
    end

    -- 消息分发
    mgr.dispatch(head, content)
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

function handle.send(sock_id, head, content)
    local pk = packet:new()
    pk:pack(head.mid, head.sid, head.clientId, content)
    local ok = pcall(websocket.write, sock_id, pk:data(), "binary", 0x02)
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
