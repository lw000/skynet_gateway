package.path = package.path .. ";./service/?.lua;"
local skynet = require("skynet")
local websocket = require("http.websocket")
local packet = require("network.packet")
local skyhelper = require("skycommon.helper")
require("skynet.manager")
require("service_config.type")
require("proto_map.proto_map")

local handle = {
    name = "gate_server_agent",
    sock_id = -1,
    debug = false,
    -- center_server_id = -1,
    -- gate_server_id = -1,
}

function handle.START(sock_id, protocol, addr, content)
    -- handle.center_server_id = content.center_server_id
    -- handle.gate_server_id = content.gate_server_id

    local ok, err = websocket.accept(sock_id, handle, protocol, addr)
    if err then
        skynet.error(err)
        return 1, "websocket.accept fail"
    end
    
    return 0
end

function handle.STOP()

end

function handle.ON_MESSAGE(head, content)
    handle.send(handle.sock_id, head.mid, head.sid, head.clientId, content)
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
        skynet.error("<: agent message","mid=" .. mid,"sid=" .. sid,"checkCode=" .. checkCode,"clientId=" .. clientId,"len=" .. string.len(pk:data()))
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

    -- 内容
    local content = {
        data = pk:data()
    }

    local forward_message_ = function(sock_id, head, content)
        -- skyhelper.sendLocal(handle.center_server_id, "message", head, content)
        skyhelper.send(SERVICE_TYPE.CENTER.NAME, "message", head, content)
        -- local ret, data = skyhelper.call(handle.center_server_id, "message", head, content)
        -- local ret, data = skyhelper.call(SERVICE_TYPE.CENTER.NAME, "message", head, content)
        -- if 0 == ret then
        --     handle.send(sock_id, head.mid, head.sid, head.clientId, data)
        -- else
        --     skynet.error("agent do call error")
        -- end
    end
    skynet.fork(forward_message_, sock_id, head, content)
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
    skynet.register(".agent")
end

skynet.start(dispatch)
