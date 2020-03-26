local skynet = require("skynet")
local cjson = require("cjson")
local skyhelper = require("skycommon.helper")
require("common.export")

local function skynet_db_call(mid, sid, content)
    local ok, reply = pcall(skyhelper.call, SERVICE_TYPE.DB.NAME, "dispatch_call_message", mid, sid, SERVICE_TYPE.LOBBY.NAME, content)
    if ok and reply ~= nil then
        -- dump(ok, "ok")
        -- dump(reply, "reply")
        return reply
    end
end

local function skynet_db_send(mid, sid, content)
    pcall(skyhelper.send, SERVICE_TYPE.DB.NAME, "dispatch_send_message", mid, sid, SERVICE_TYPE.LOBBY.NAME, content)
end

local logic = {}

-- 请求注册
function logic.onReqRegist(head, content)
    dump(head, "head")
    dump(content, "reqRegist")
    return skynet_db_call(head.mid, head.sid, content)
end

-- 请求登录
function logic.onReqLogin(head, content)
    dump(head, "head")
    dump(content, "reqLogin")
    return skynet_db_call(head.mid, head.sid, content)
end

return logic