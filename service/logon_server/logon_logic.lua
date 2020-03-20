local skynet = require("skynet")
local cjson = require("cjson")
local skyhelper = require("skycommon.helper")
require("common.export")
require("core.define")

local logic = {

}

-- 请求登录
function logic.onReqLogin(mid, sid, content)
    assert(content ~= nil)
    if content == nil then
        return 1, "content is nil"
    end

    dump(content, "content")

    skynet.error("接受到请求登录消息")

    return 0
end

return logic