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

    local ok, reply = pcall(skyhelper.call, SERVICE_TYPE.DB.NAME, "on_server_message", head, content)
    if not reply then
        return nil
    end
    return reply
end

-- 请求登录
function logic.onReqLogin(head, content)
    -- dump(head, "head")
    -- dump(content, "reqLogin")

    local ok, reply = pcall(skyhelper.call, SERVICE_TYPE.DB.NAME, "on_server_message", head, content)
    if not reply then
        return nil
    end
    return reply
end

return logic