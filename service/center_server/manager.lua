local skynet = require("skynet")
local skyhelper = require("skycommon.helper")
local route = require("center_server.route")
require("common.export")
require("service_config.type")

local manager = {
    servername = "",   -- 服务名字
}

function manager.start(servername)
    assert(servername ~= nil)
    assert(type(servername) == "string")
    manager.servername = servername
end

function manager.stop()

end

function manager.dispatch(head, content)
    assert(head ~= nil)
    -- skynet.error(string.format(manager.servername .. ":> mid=%d", head.mid))
    -- dump(head, "head")

    local service = route[head.mid]
    if not service then
        local errmsg = "unknown " .. manager.servername .. " mid command" 
        skynet.error(errmsg)
        return nil, errmsg 
    end
    return skyhelper.send(service.name, "message", head, content)
end

return manager