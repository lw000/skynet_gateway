local skynet = require("skynet")
local cjson = require("cjson")
local skyhelper = require("skycommon.helper")
require("common.export")
require("core.define")
require("proto_map.proto_map")

local logic = {

}

-- 请求登录
function logic.onReqLogin(head, content)
    assert(head ~= nil)
    assert(content ~= nil)

    if head == nil then
        return 1, "head is nil"
    end

    if content == nil then
        return 2, "content is nil"
    end

    local ack = proto_map.decode_ReqLogin(content.data)
    dump(ack, "ack")

    local ack = proto_map.encode_AckLogin(
        {
            result = 1,
            errmsg = "登录成功",
        }
    )
    return 0, ack
end

return logic