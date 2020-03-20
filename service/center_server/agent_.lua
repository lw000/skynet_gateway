package.path = package.path .. ";./service/?.lua;"
local skynet = require("skynet")
local websocket = require("http.websocket")
local packet = require("network.packet")
require("skynet.manager")
require("proto_map.proto_map")

local handle = {
    handlename = "center agent",
    debug = false
}

local msgs_switch = {
    [0x0000] = {
        name = "MDM_HEARTBEAT",
        [0x0000] = {
            name = "SUB_HEARTBEAT",
            dest = "心跳",
            req = nil,
            ack = nil,
            fn = function(sock_id, mid, sid, clientId, req)
                skynet.error("心跳", os.date("%Y-%m-%d %H:%M:%S", os.time()))
            end
        }
    },
    [0x0001] = {
        name = "MDM_CORE",
        [0x0001] = {
            name = "SUB_CORE_REGISTER",
            dest = "注册服务",
            req = proto_map.encode_ReqRegistService,
            ack = proto_map.encode_AckRegistService,
            fn = function(sock_id, mid, sid, clientId, req)
                dump(req, "ReqRegistService")
                local content = proto_map.encode_AckRegService(
                    {
                        result = 0,
                        serverId = 10000,
                        errmsg = "客户端注册成功"
                    }
                )
                handle.send(sock_id, mid, sid, clientId, content)
            end
        }
    }
}

function handle.connect(sock_id)
    -- skynet.error("ws connect from: " .. tostring(sock_id))
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
        skynet.error(
            "<: message",
            "sock_id=" .. sock_id,
            "mid=" .. mid,
            "sid=" .. sid,
            "checkCode=" .. checkCode,
            "clientId=" .. clientId,
            "dataLen=" .. string.len(pk:data())
        )
    end
    
    local tmsg = msgs_switch[mid]
    if tmsg == nil then
        skynet.error("<: " .. handle.handlename .. " unknown command [" .. "mid=".. mid .. "]")
        return
    end

    local msgmap = tmsg[sid]
    if msgmap == nil then
        skynet.error("<: " .. handle.handlename .. " unknown command [" .. " sid=" .. sid .. "]")
        return
    end
    
    if msgmap then
        if msgmap.fn then
            local req = nil
            if msgmap.req and pk:data() then
                req = msgmap.req(pk:data())
            end
            skynet.fork(msgmap.fn, sock_id, mid, sid, clientId, req)
        end
    else
        skynet.error("<: unknown command [" .. "mid= ".. mid .. " sid=" .. sid .. "]")
    end
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

function handle.send(wsid, mid, sid, clientid, content)
    local pk = packet:new()
    pk:pack(mid, sid, clientid, content)
    if pk:data() == nil then
        skynet.error("packet create error")
        return 1, "packet create error"
    end
    websocket.write(wsid, pk:data(), "binary", 0x02)
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
