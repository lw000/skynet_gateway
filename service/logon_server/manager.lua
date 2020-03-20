local skynet = require("skynet")
local logic = require("logon_server.logic")
require("common.export")
require("service_config.type")
require("proto_map.proto_map")

local manager = {
    servername = nil,   -- 服务名字
    methods = nil,      -- 业务处理接口映射表
}

function manager.start(servername)
    assert(servername ~= nil)
    assert(type(servername) == "string")
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
  
    -- skynet.error(string.format(manager.servername .. ":> mid=%d sid=%d", head.mid, head.sid))
    
    -- 解包接口
    local cmd = proto_map.query(head.mid, head.sid)
    if cmd == nil then
        local errmsg = "unknown " .. manager.servername .. " sid command" 
        skynet.error(errmsg)
        return nil, errmsg 
    end

    -- 查询业务处理函数
    local method = manager.methods[head.sid]
    assert(method ~= nil)
    if not method then
        local errmsg = "unknown " .. manager.servername .. " sid command" 
        skynet.error(errmsg)
        return nil, errmsg 
    end
    -- pb解包
    local reqContent = cmd.req(content.data)
    local ret, ackContent = method.func(head, reqContent)
    -- dump(result, "result")
    if 0 == ret then
        -- body
    end
    -- pb封包
    local ack = cmd.ack(ackContent)

    return ret, ack
end

return manager