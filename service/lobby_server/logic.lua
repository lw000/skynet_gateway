local skynet = require("skynet")
local cjson = require("cjson")
local skyhelper = require("skycommon.helper")
require("common.export")

local logic = {

}

-- 请求注册
function logic.onReqRegist(head, content)
    -- dump(head, "head")
    -- dump(content, "reqRegist")

    local reply = skyhelper.call(SERVICE_TYPE.DB.NAME, "message", head, content)
    return reply
end

-- 请求登录
function logic.onReqLogin(head, content)
    -- dump(head, "head")
    -- dump(content, "reqLogin")

    local reply = skyhelper.call(SERVICE_TYPE.DB.NAME, "message", head, content)
    return reply
end

return logic