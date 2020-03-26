local skynet = require("skynet")
local logic = require("db_server.service.db_logic_func")
require("common.export")
require("service_config.type")
require("service_config.cmd")

-- 业务处理接口映射表
local methods = {
    [DB_CMD.SUB.REGIST] = {func=logic.onReqRegist, desc="用户注册"},
    [DB_CMD.SUB.LOGON] = {func=logic.onReqLogin, desc="用户登录"},
    [DB_CMD.SUB.LOG] = {func=logic.onWriteLog, desc="记录请求日志"}
}

local manager = {
    servername = "",   -- 服务名字
    debug = false,
}

function manager.start(servername, debug)
    assert(servername ~= nil)
    assert(type(servername) == "string")
    manager.servername = servername
    manager.debug = debug
end

function manager.stop()
    
end

function manager.dispatch(dbconn, head, content)
    assert(dbconn ~= nil)
    assert(head ~= nil and type(head)== "table")
    assert(content ~= nil and type(content)== "table")
    
    if manager.debug then
        skynet.error(string.format(manager.servername .. " mid=%d sid=%d", head.mid, head.sid))
    end

    -- 查询业务处理函数
    local method = methods[head.sid]
    assert(method ~= nil)
    if not method then
        local errmsg = "unknown " .. manager.servername .. " [sid=" .. tostring(head.sid) .. "] command"
        skynet.error(errmsg)
        return nil, errmsg
    end
    
    return method.func(dbconn, head, content)
end

return manager