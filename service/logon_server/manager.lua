local skynet = require("skynet")
local skyhelper = require("skycommon.helper")
local logic = require("logon_server.logic")
require("common.export")
require("service_config.type")
require("proto_map.proto_map")

-- 业务处理接口映射表
local methods = {
    [LOGON_CMD.SUB.REGIST] = {func=logic.onReqRegist, desc="请求登录"},
    [LOGON_CMD.SUB.LOGON] = {func=logic.onReqLogin, desc="请求登录"},
    [LOGON_CMD.SUB.CHAT] = {func=logic.onChat, desc="聊天信息"}
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

    if cmd.req == nil then
        local errmsg = manager.servername .. "[PB]协议解包接口不存在"
        skynet.error(errmsg)
        return nil, errmsg 
    end

    -- 1. [PB]协议·解包
    local reqContent = cmd.req(content.data)

    -- 2. 业务处理
    local ackContent = method.func(head, reqContent)
    if ackContent == nil then
        return
    end

    if cmd.ack == nil then
        local errmsg = manager.servername .. "[PB]协议封包接口不存在"
        skynet.error(errmsg)
        return nil, errmsg
    end

    -- 3. [PB]协议·封包
    local ack = cmd.ack(ackContent)
    
    -- 转发消息
    -- skyhelper.sendLocal(head.agent, "on_message", head, ack)
    skyhelper.send(SERVICE_TYPE.CENTER.NAME, "on_message", head, ack)
end

return manager