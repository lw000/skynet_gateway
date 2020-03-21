local skynet = require("skynet")
local logic = require("redis_server.logic")
require("common.export")
require("service_config.type")

-- 业务处理接口映射表
local methods = {
    [REDIS_CMD.SUB_LOG] = {func=logic.onWriteLog, desc="记录请求日志"}
}

local manager = {
    servername = nil,   -- 服务名字   
}

function manager.start(servername)
    assert(servername ~= nil)
    assert(type(servername) == "string")
    manager.servername = servername
end

function manager.stop()

end

function manager.dispatch(redisConn, head, content)
    assert(redisConn ~= nil)

    -- skynet.error(string.format(manager.servername .. ":> mid=%d sid=%d", head.mid, head.sid))

    -- 查询业务处理函数
    local method = methods[head.sid]
    assert(method ~= nil)
    if not method then
        local errmsg = "unknown " .. manager.servername .. " [sid=" .. tostring(head.sid) .. "] command"
        skynet.error(errmsg)
        return nil, errmsg 
    end
    return method.func(redisConn, content)
end

return manager