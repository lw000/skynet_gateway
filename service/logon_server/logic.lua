local skynet = require("skynet")
local cjson = require("cjson")
local skyhelper = require("skycommon.helper")
require("common.export")
require("service_config.type")
require("proto_map.proto_map")

local logic = {

}

-- 请求登录
function logic.onReqLogin(head, content)
    -- dump(content, "reqLogin")
    return 0, {
        result = 1,
        errmsg = "登录成功",
    }
end

-- 聊天信息
function logic.onChat(head, content)
    -- dump(content, "chatMessage")
    return 0, {result = 1}
end

return logic