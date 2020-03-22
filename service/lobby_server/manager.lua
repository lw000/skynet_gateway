local skynet = require("skynet")
local skyhelper = require("skycommon.helper")
local logic = require("lobby_server.logic")
require("common.export")
require("service_config.type")
require("proto_map.proto_map")

-- 业务处理接口映射表
local methods = {
    [LOBBY_CMD.SUB.REGIST] = {func=logic.onReqRegist, desc="请求登录"},
    [LOBBY_CMD.SUB.LOGON] = {func=logic.onReqLogin, desc="请求登录"},
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
    
    -- 查询业务处理函数
    local method = methods[head.sid]
    assert(method ~= nil)
    if not method then
        local errmsg = "unknown " .. manager.servername .. " [sid=" .. tostring(head.sid) .. "] command"
        skynet.error(errmsg)
        return nil, errmsg
    end

    local ack, err = proto_map.exec(head, content, method.func)
    if err ~= nil then
        skynet.error(err)
        return nil, err 
    end
    
    -- 不需要转发
    if ack == nil then
        return
    end

    -- 转发消息
    skyhelper.send(SERVICE_TYPE.CENTER.NAME, "service_message", head, ack)
end

return manager