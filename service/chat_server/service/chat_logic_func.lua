local skynet = require("skynet")
local cjson = require("cjson")
local skyhelper = require("skycommon.helper")
require("common.export")

local logic = {

}

local msg_index = 0

-- 聊天信息
function logic.onChat(head, content)
    -- dump(head, "head")
    -- dump(content, "chatMessage")
    msg_index = msg_index + 1
    return {
        from = content.from,
        result = msg_index
    }
end

-- dump(logic, "logic")

return logic