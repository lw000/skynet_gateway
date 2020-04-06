local skynet = require("skynet")
local cjson = require("cjson")
local skyhelper = require("skycommon.helper")
local utils = require("utils")

local logic = {}

local msg_index = 0

-- 聊天信息
function logic.onChat(head, content)
    -- utils.dump(head, "head")
    -- utils.dump(content, "chatMessage")
    msg_index = msg_index + 1
    return {
        from = content.from,
        result = msg_index
    }
end

return logic