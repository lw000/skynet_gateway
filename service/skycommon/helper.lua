local skynet = require("skynet")
require("common.export")

local skyhelper = {}

-- 参数检查
local function check(servername, method, head)
    -- dump(servername, "servername")
    -- dump(method, "method")
    -- dump(head, "head")
    assert(servername ~= nil)
    assert(method ~= nil and type(method) == "string" and method ~= "")
    assert(head ~= nil and type(head) == "table")
    assert(head.mid ~= nil and type(head.mid) == "number" and head.mid >= 0)
    assert(head.sid ~= nil and type(head.sid) == "number" and head.sid >= 0)
end

function skyhelper.send(servername, method, head, content)
    check(servername, method, head)
    skynet.send(servername, "lua", method, head, content)
end

function skyhelper.call(servername, method, head, content)
    check(servername, method, head)
    return skynet.call(servername, "lua", method, head, content)
end

return skyhelper