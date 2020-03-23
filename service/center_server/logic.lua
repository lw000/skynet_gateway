local skynet = require("skynet")
local cjson = require("cjson")
local skyhelper = require("skycommon.helper")
require("common.export")

local logic = {

}

local serverId = 10000

-- 服务注册
function logic.onRegist(head, content)
    -- dump(head, "head")
    -- dump(content, "ReqRegService")
    serverId = serverId + 1
    return {
        result = 0,                     -- 操作结果: 0-成功; 非0-失败
        serverId = serverId,	        -- 服务器ID
        errmsg = "服务注册成功",         -- 描述消息
    }
end

return logic