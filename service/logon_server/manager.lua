local skynet = require("skynet")
local skyhelper = require("skycommon.helper")
local logic = require("logon_server.logic")
require("common.export")
require("service_config.type")
require("proto_map.proto_map")

-- 业务处理接口映射表
local methods = {
    [LOGON_CMD.SUB.LOGON] = {func=logic.onReqLogin, desc="请求登录"},
    [LOGON_CMD.SUB.CHAT] = {func=logic.onChat, desc="聊天信息"}
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

function manager.dispatch(head, content)
    -- skynet.error(string.format(manager.servername .. ":> mid=%d sid=%d", head.mid, head.sid))
    
    -- 解包接口
    local cmd = proto_map.query(head.mid, head.sid)
    if cmd == nil then
        local errmsg = "unknown " .. manager.servername .. " [mid=" .. tostring(head.mid) .. " sid=" .. tostring(head.sid) .. "] command"
        skynet.error(errmsg)
        return nil, errmsg 
    end

    -- 查询业务处理函数
    local method = methods[head.sid]
    assert(method ~= nil)
    if not method then
        local errmsg = "unknown " .. manager.servername .. " [sid=" .. tostring(head.sid) .. "] command"
        skynet.error(errmsg)
        return nil, errmsg 
    end

    -- 1. pb解包
    local reqContent = cmd.req(content.data)

    -- 2. 业务处理
    local ret, ackContent = method.func(head, reqContent)
    if 0 == ret then
        -- body
    end

    -- 3. pb封包
    local ack = cmd.ack(ackContent)

    skyhelper.sendLocal(head.agent, "on_message", head, ack)

    return ret, ack
end

return manager