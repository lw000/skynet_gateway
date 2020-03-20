local skynet = require("skynet")
local logic = require("redis_server.redis_logic")
require("common.export")
require("core.define")

local manager = {
    servername = nil,   -- 服务名字
    methods = nil,      -- 业务处理接口映射表
}

function manager.start(servername)
    assert(servername ~= nil) 
    manager.servername = servername

    -- 注册业务处理接口
    if manager.methods == nil then
		manager.methods = {}
    end
    manager.methods[REDIS_CMD.SUB_LOG] = {func=logic.onWriteLog, desc="记录请求日志"}
    -- dump(manager.methods, manager.servername .. ".command.methods")
end

function manager.stop()
    manager.methods = nil
end

function manager.dispatch(redisConn, mid, sid, content)
    assert(redisConn ~= nil)
    assert(mid ~= nil and mid >= 0)
    assert(mid ~= nil and sid >= 0)
    
    -- 查询业务处理函数
    local method = manager.methods[sid]
    -- dump(method,  manager.servername .. ".method")
    assert(method ~= nil)
    if not method then
        local errmsg = "unknown " .. manager.servername .. " sid command" 
        skynet.error(errmsg)
        return nil, errmsg 
    end
    return method.func(redisConn, content)
end

return manager