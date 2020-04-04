local skynet = require("skynet")
require("utils")

local skyhelper = {}

-- 参数检查
local function check(servername, method)
    assert(servername ~= nil)
    assert(method ~= nil and type(method) == "string" and method ~= "")
    return servername, method
end

function skyhelper.send(servername, method, ...)
    servername, method = check(servername, method)
    skynet.send(servername, "lua", method, ...)
end

function skyhelper.call(servername, method, ...)
    servername, method = check(servername, method)
    return skynet.call(servername, "lua", method, ...)
end

return skyhelper