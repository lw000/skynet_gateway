local skynet = require("skynet")
local skyhelper = require("helper")
local logic = require("service.chat_logic_func")
local utils = require("utils")
require("service_type")
require("proto_map")

-- 业务处理接口映射表
local methods = {
    [CHAT_CMD.SUB.CHAT] = {func=logic.onChat, desc="聊天信息"}
}

local manager = {
    debug = false,
    servername = "",   -- 服务名字
}

function manager.start(servername, debug)
    assert(servername ~= nil)
    assert(type(servername) == "string")
    manager.servername = servername
    manager.debug = debug
end

function manager.stop()

end

function manager.dispatch(head, content)
    assert(head ~= nil and type(head)== "table")
    assert(content ~= nil and type(content)== "table")
    
    if manager.debug then
        skynet.error(string.format(manager.servername .. ":> mid=%d sid=%d", head.mid, head.sid))
    end
 
    -- 查询业务处理函数
    local method = methods[head.sid]
    assert(method ~= nil)
    if not method then
        local errmsg = "unknown " .. manager.servername .. " [sid=" .. tostring(head.sid) .. "] command"
        skynet.error(errmsg)
        return nil, errmsg
    end

    local ret, ack = proto_map.exec(head, content, method.func)
    if ret ~= 0 then
        skynet.error(ret, ack)
        return ack 
    end
    
    -- utils.dump(head, manager.servername .. ".head")

    -- 转发消息
    skyhelper.send(head.center_agent, "send_client_message", head, ack)
end

return manager