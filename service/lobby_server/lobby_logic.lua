local skynet = require("skynet")
local cjson = require("cjson")
local skyhelper = require("helper")
require("utils")

local function skynet_db_call(command, ...)
    local ok, data = pcall(skyhelper.call, SERVICE_TYPE.DB.NAME, "dispatch_call_message", command, SERVICE_TYPE.LOBBY.NAME, ...)
    if ok and data ~= nil then
        -- dump(ok, "ok")
        -- dump(data, "data")
        return data
    end
end

local function skynet_db_send(command, ...)
    pcall(skyhelper.send, SERVICE_TYPE.DB.NAME, "dispatch_send_message", command, SERVICE_TYPE.LOBBY.NAME, ...)
end

local logic = {}

-- 请求注册
function logic.onReqRegist(head, content)
    -- dump(head, "head")
    -- dump(content, "reqRegist")
    return skynet_db_call("register_account", content)
end

-- 请求登录
function logic.onReqLogin(head, content)
    -- dump(head, "head")
    -- dump(content, "reqLogin")
    return skynet_db_call("login_account", content)
end

return logic