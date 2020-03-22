local skynet = require("skynet")
local skyhelper = require("skycommon.helper")
local route = require("center_server.route")
local logic = require("center_server.logic")
require("common.export")
require("service_config.type")
require("service_config.cmd")

-- 业务处理接口映射表
local methods = {
    [CENTER_CMD.SUB.REGIST] = {func=logic.onRegist, desc="服务注册"}
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
    assert(head ~= nil)
    
    -- skynet.error(string.format(manager.servername .. ":> mid=%d", head.mid))

    -- 路由服务器消息
    if head.mid == CENTER_CMD.MDM then
        -- 查询业务处理函数
        local method = methods[head.sid]
        assert(method ~= nil)
        if method == nil then
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
        skyhelper.send(SERVICE_TYPE.CENTER.NAME, "on_core_message", head, ack)
        
        return
    end

    -- 其它服务器消息，则转发到对应服务器
    local service = route[head.mid]
    if not service then
        local errmsg = "unknown " .. manager.servername .. " mid=" .. tostring(head.mid) .. " command" 
        skynet.error(errmsg)
        return nil, errmsg 
    end
    return skyhelper.send(service.name, "message", head, content)
end

return manager