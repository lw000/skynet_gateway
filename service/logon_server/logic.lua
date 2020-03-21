local skynet = require("skynet")
local cjson = require("cjson")
local skyhelper = require("skycommon.helper")
require("common.export")

local logic = {

}

-- 请求登录
function logic.onReqLogin(head, content)
    -- dump(head, "head")
    dump(content, "reqLogin")
    return {
        result = 0,
        errmsg = "登录成功",
    }
end

local msg_index = 0

-- 聊天信息
function logic.onChat(head, content)
    -- dump(head, "head")
    dump(content, "chatMessage")
    msg_index = msg_index + 1
    return {result = msg_index}
end

return logic