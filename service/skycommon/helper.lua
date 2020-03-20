local skynet = require("skynet")
require("common.export")

local skyhelper = {

}

-- 参数检查
local function checkparam(servername, rpcname, mid, sid)
    assert(type(servername) == "string" and servername ~= "")
    assert(type(rpcname) == "string" and rpcname ~= "" )
    assert(type(mid) == "number" and mid >= 0)
    assert(type(sid) == "number" and sid >= 0)
end

-- send发送全局服务消息
function skyhelper.send(servername, rpcname, mid, sid, content)
    checkparam(servername, rpcname, mid, sid)
    local server_id = skynet.queryservice(true, servername)
    skynet.send(server_id, "lua", rpcname, mid, sid, content)
end

-- call发送全局服务消息
function skyhelper.call(servername, rpcname, mid, sid, content)
    checkparam(servername, rpcname, mid, sid)
    local server_id = skynet.queryservice(true, servername)
    return skynet.call(server_id, "lua", rpcname, mid, sid, content)
end

-- sendLocal发送本地服务消息
function skyhelper.sendLocal(servername, rpcname, mid, sid, content)
    checkparam(servername, rpcname, mid, sid)
    local server_id = skynet.localname(servername)
    assert(server_id ~= nil)
    if server_id == nil then
        return
    end
    skynet.send(server_id, "lua", rpcname, mid, sid, content)
end

-- callLocal发送本地服务消息
function skyhelper.callLocal(servername, rpcname, mid, sid, content)
    checkparam(servername, rpcname, mid, sid)
    local server_id = skynet.localname(servername)
    assert(server_id ~= nil)
    if server_id == nil then
        return 1, "service not found"
    end
    return skynet.call(server_id, "lua", rpcname, mid, sid, content)
end

return skyhelper