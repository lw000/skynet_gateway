local skynet = require("skynet")
local logic = require("redis_server.logic")
require("common.export")
require("service_config.define")

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

function manager.dispatch(redisConn, head, content)
    assert(redisConn ~= nil)
    assert(head ~= nil and type(head) == "table")
    assert(content ~= nil and type(content) == "table")
    assert(head.mid ~= nil and head.mid >= 0)
    assert(head.sid ~= nil and head.sid >= 0)

    -- skynet.error(string.format(manager.servername .. ":> mid=%d sid=%d", head.mid, head.sid))
        
    if head.mid ~= REDIS_CMD.MDM_REDIS then
		local errmsg = "unknown " .. manager.servername .. " message command"
		skynet.error(errmsg)
		return -1, errmsg
	end

    -- 查询业务处理函数
    local method = manager.methods[head.sid]
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