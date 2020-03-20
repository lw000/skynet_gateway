local skynet = require("skynet")
require("common.export")

local logic = {
}

-- 请求登录
function logic.onReqLogin(mid, sid, content)
    assert(content ~= nil)
    if content == nil then
        return 1, "content is nil"
    end

    skynet.error("请求登录")

    return 0
end

return logic