local skynet = require("skynet")
local logic = require("db_server.logic")
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
}

function manager.start(servername)
    assert(servername ~= nil)
    assert(type(servername) == "string")
    manager.servername = servername
end

function manager.stop()
end

function manager.dispatch(dbconn, head, content)
    assert(dbconn ~= nil)

    -- skynet.error(string.format(manager.servername .. ":> mid=%d sid=%d", head.mid, head.sid))

    -- 查询业务处理函数
    local method = methods[head.sid]
    assert(method ~= nil)
    if not method then
        local errmsg = "unknown " .. manager.servername .. " [sid=" .. tostring(head.sid) .. "] command"
        skynet.error(errmsg)
        return nil, errmsg
    end

    -- skynet.error(string.format(manager.servername .. ":> mid=%d sid=%d", head.mid, head.sid))
    
    return method.func(dbconn, head, content)

    -- -- 查询业务处理函数
    -- local method = methods[head.sid]
    -- assert(method ~= nil)
    -- if not method then
    --     local errmsg = "unknown " .. manager.servername .. " [sid=" .. tostring(head.sid) .. "] command"
    --     skynet.error(errmsg)
    --     return nil, errmsg
    -- end

    -- local ack, err = proto_map.exec(head, content, function(head, content)
    --     return method.func(dbconn, head, content)
    -- end)

    -- if err ~= nil then
    --     skynet.error(err)
    --     return nil, err 
    -- end
    
    -- -- 不需要转发
    -- if ack == nil then
    --     return
    -- end

    -- return ack
end

return manager