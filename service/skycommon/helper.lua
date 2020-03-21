local skynet = require("skynet")
require("common.export")

local skyhelper = {}

-- 参数检查
local function check(servername, rpcmethod, head)
    assert(servername ~= nil)
    assert(rpcmethod ~= nil and type(rpcmethod) == "string" and rpcmethod ~= "")
    assert(head ~= nil and type(head) == "table")
    assert(head.mid ~= nil and type(head.mid) == "number" and head.mid >= 0)
    assert(head.sid ~= nil and type(head.sid) == "number" and head.sid >= 0)
end

function skyhelper.send(servername, rpcmethod, head, content)
    check(servername, rpcmethod, head)
    skynet.send(servername, "lua", rpcmethod, head, content)
end

function skyhelper.call(servername, rpcmethod, head, content)
    check(servername, rpcmethod, head)
    return skynet.call(servername, "lua", rpcmethod, head, content)
end

return skyhelper