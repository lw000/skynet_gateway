local skynet = require("skynet")
require("common.export")

local skyhelper = {

}

-- 参数检查
local function checkparam(servername, rpcname, head)
    assert(servername ~= nil and type(servername) == "string" and servername ~= "")
    assert(rpcname ~= nil and type(rpcname) == "string" and rpcname ~= "" )
    assert(head ~= nil and type(head) == "table")
    assert(head.mid ~= nil and type(head.mid) == "number" and head.mid >= 0)
    assert(head.sid ~= nil and type(head.sid) == "number" and head.sid >= 0)
end

-- send发送全局服务消息
function skyhelper.send(servername, rpcname, head, content)
    checkparam(servername, rpcname, head)
    local server_id = skynet.queryservice(true, servername)
    skynet.send(server_id, "lua", rpcname, head, content)
end

-- call发送全局服务消息
function skyhelper.call(servername, rpcname, head, content)
    checkparam(servername, rpcname, head)
    local server_id = skynet.queryservice(true, servername)
    return skynet.call(server_id, "lua", rpcname, head, content)
end

-- sendLocal发送本地服务消息
function skyhelper.sendLocal(servername, rpcname, head, content)
    checkparam(servername, rpcname, head)
    local server_id = skynet.localname(servername)
    assert(server_id ~= nil)
    if server_id == nil then
        return
    end
    skynet.send(server_id, "lua", rpcname, head, content)
end

-- callLocal发送本地服务消息
function skyhelper.callLocal(servername, rpcname, head, content)
    checkparam(servername, rpcname, head)
    local server_id = skynet.localname(servername)
    assert(server_id ~= nil)
    if server_id == nil then
        return 1, "service not found"
    end
    return skynet.call(server_id, "lua", rpcname, head, content)
end

return skyhelper