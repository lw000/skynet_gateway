local skynet = require("skynet")
local cjson = require("cjson")
local skyhelper = require("skycommon.helper")
require("common.export")
require("service_config.cmd")

local service_id = 10000

local service_register = {}

local logic = {}

-- 服务注册
function logic.onRegist(head, content)
    -- dump(head, "head")
    -- dump(content, "ReqRegService")

    -- dump(service_register, "service_register")

    local servers = service_register[content.svrType]
    if servers == nil then
        servers = {}
        service_register[content.svrType] = servers
    end

    service_id = service_id + 1
    table.insert(servers, service_id)

    local reply = {
        result = 0,                     -- 操作结果: 0-成功; 非0-失败
        serverId = service_id,	        -- 服务器ID
        errmsg = "服务注册成功",         -- 描述消息
    }
    return reply
end

-- 服务卸载
function logic.onUnregist(head, content)
    dump(head, "head")
    dump(content, "ReqRegService")

end

return logic