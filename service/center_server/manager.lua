local skynet = require("skynet")
local logic = require("center_server.logic")
local skyhelper = require("skycommon.helper")
local routemap = require("center_server.routemap")
require("common.export")
require("service_config.type")

local manager = {
    servername = nil,   -- 服务名字
}

function manager.start(servername)
    assert(servername ~= nil)
    assert(type(servername) == "string")
    manager.servername = servername
end

function manager.stop()
    manager.methods = nil
end

function manager.dispatch(head, content)
    assert(head ~= nil and type(head)== "table")
    assert(content ~= nil and type(content)== "table")
    assert(head.mid ~= nil and head.mid >= 0)
    assert(head.mid ~= nil and head.sid >= 0)

    -- skynet.error(string.format(manager.servername .. ":> mid=%d sid=%d", head.mid, head.sid))

    local route = routemap[head.mid]
    -- dump(route, "route")
    if not route then
        local errmsg = "unknown " .. manager.servername .. "mid command" 
        skynet.error(errmsg)
        return nil, errmsg 
    end
    return skyhelper.callLocal(route.to, "message", head, content)
end

return manager