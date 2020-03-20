local skynet = require("skynet")
local logic = require("center_server.logic")
local skyhelper = require("skycommon.helper")
local forwardmap = require("center_server.route_map")
require("common.export")
require("service_config.define")

local manager = {
    servername = nil,   -- 服务名字
}

function manager.start(servername)
    assert(servername ~= nil) 
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

    local forward = forwardmap[head.mid]
    -- dump(forward, "forward")
    if not forward then
        local errmsg = "unknown " .. manager.servername .. "mid command" 
        skynet.error(errmsg)
        return nil, errmsg 
    end
    return skyhelper.callLocal(forward.TO, "message", head, content)
end

return manager