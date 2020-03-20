package.path = package.path .. ";./service/?.lua;"
local skynet = require("skynet")
local websocket = require("http.websocket")
local packet = require("network.packet")
local skyhelper = require("skycommon.helper")
require("skynet.manager")
require("core.define")
require("proto_map.proto_map")

local handle = {
    sock_id = -1,
    debug = false
}

function handle.connect(sock_id)
    handle.sock_id = sock_id
    skynet.error("ws connect from: " .. tostring(sock_id))
end

function handle.handshake(sock_id, header, url)
    local addr = websocket.addrinfo(sock_id)
    skynet.error("ws handshake from", "addr=" .. addr, "url=" .. url)
    
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
    local checkCode = pk:checkCode()
    local clientId = pk:clientId()

    -- 包校验码检查
    if checkCode  ~= 123456 then
        -- body
    end

    if handle.debug then
        skynet.error("<: agent message","mid=" .. mid,"sid=" .. sid,"checkCode=" .. checkCode,"clientId=" .. clientId,"len=" .. string.len(pk:data()))
    end

    local head = {
        mid = pk:mid(),
        sid = pk:sid(),
        ver = pk:ver(),
        checkCode = pk:checkCode(),
        clientId = pk:clientId(),
    }

    local content = {
        data = pk:data()
    }

    skynet.fork(function(head, content)
        local ok, data = skyhelper.callLocal(SERVICE_CONF.CENTER.NAME, "message", head, content)
        if ok then
            handle.send(sock_id, head.mid, head.sid, head.clientId, data)
        else
            skynet.error("agent do call error")
        end
    end, head, content)
end

function handle.ping(sock_id)
    skynet.error("ws ping from: " .. tostring(sock_id) .. "\n")
end

function handle.pong(sock_id)
    skynet.error("ws pong from: " .. tostring(sock_id))
end

function handle.close(sock_id, code, reason)
    skynet.error("ws close from: " .. tostring(sock_id), code, reason)
end

function handle.error(sock_id)
    skynet.error("ws error from: " .. tostring(sock_id))
end

function handle.send(sock_id, mid, sid, clientid, content)
    local pk = packet:new()
    pk:pack(mid, sid, clientid, content)
    if pk:data() == nil then
        skynet.error("packet create error")
        return 1, "packet create error"
    end
    websocket.write(sock_id, pk:data(), "binary", 0x02)
    return 0
end

skynet.init(
    function()
        skynet.error("agent init")
    end
)

local function dispatch()
    skynet.dispatch(
        "lua",
        function(session, address, sock_id, protocol, addr)
            skynet.error("accept client", "sock_id=" .. sock_id, "addr=" .. skynet.address(address), "addr=" .. addr)
            local ok, err = websocket.accept(sock_id, handle, protocol, addr)
            if err then
                skynet.error(err)
            end
        end
    )
    skynet.register(".agent")
end

skynet.start(dispatch)
