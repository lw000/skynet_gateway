local skynet = require("skynet")
local logic = require("center_server.logic")
local skyhelper = require("skycommon.helper")
local forwardmap = require("center_server.route_map")
require("common.export")
require("core.define")

local manager = {
    methods = nil,   -- 业务处理接口映射表
    servername = nil,   -- 服务名字
}

function manager.start(servername)
    assert(servername ~= nil) 
    manager.servername = servername

    if manager.methods == nil then
		manager.methods = {}
    end

    -- 注册业务处理接口
    -- manager.methods[CENTER_CMD.SUB_LOGIN] = {func=logic.onReqLogin, desc="请求登录"}
    -- dump(manager.methods, manager.servername .. ".command.methods")
end

function manager.stop()
    manager.methods = nil
end

function manager.dispatch(mid, sid, content)
    assert(mid ~= nil and mid >= 0)
    assert(mid ~= nil and sid >= 0)

    local forward = forwardmap[mid]
    -- dump(forward, "forward")
    if not forward then
        local errmsg = "unknown " .. manager.servername .. "mid command" 
        skynet.error(errmsg)
        return nil, errmsg 
    end
    return skyhelper.callLocal(forward.TO, "message", mid, sid, content)
end

return manager