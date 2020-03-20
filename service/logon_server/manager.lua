local skynet = require("skynet")
local logic = require("logon_server.logic")
require("common.export")
require("service_config.define")
require("proto_map.proto_map")

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
    
    manager.methods[LOGON_CMD.SUB.LOGON] = {func=logic.onReqLogin, desc="请求登录"}
    manager.methods[LOGON_CMD.SUB.CHAT] = {func=logic.onChat, desc="聊天信息"}
    -- dump(manager.methods, manager.servername .. ".command.methods")
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

    if head.mid ~= LOGON_CMD.MDM_LOGON then
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

    local logonMethod = proto_map[LOGON_CMD.MDM_LOGON]
    -- dump(logonMethod, "logonMethod")

    -- 解包接口
    local cmd = logonMethod[head.sid]
    -- dump(cmd, "cmd")

    local req = cmd.req(content.data)
    -- dump(req, "req")

    local ret, result = method.func(head, req)
    -- dump(result, "result")
    if 0 == ret then
        -- body
    end
    -- 封包接口
    local ack = cmd.ack(result)

    return ret, ack
end

return manager