local skynet = require("skynet")
local cjson = require("cjson")
local skyhelper = require("helper")
local utils = require("utils")

local function skynet_db_call(command, ...)
    local ok, result = pcall(skyhelper.call, SERVICE_TYPE.DB.NAME, command, ...)
    if ok and result then
        -- utils.dump(ok, "ok")
        -- utils.dump(result, "result")
        return result
    end
end

local function skynet_db_send(command, ...)
    pcall(skyhelper.send, SERVICE_TYPE.DB.NAME, command, ...)
end

local logic = {}

-- 请求注册
function logic.onReqRegist(head, content)
    -- utils.dump(head, "head")
    -- utils.dump(content, "reqRegist")

    local account = content.account
    if account == "" then
        return {
            result = 1,
            errmsg = "账号为空",
        }
    end
    
    local password = content.password
    if password == "" then
        return {
            result = 2,
            errmsg = "密码为空",
        }
    end

    local result =  skynet_db_call("register_account", account, password)
    utils.dump(result, "result")

    if not result then
        return {
            result = 1,
            errmsg = "未知错误",
        }
    end

    return {
        result = 0,
        errmsg = "注册成功",
    }
end

-- 请求登录
function logic.onReqLogin(head, content)
    -- utils.dump(head, "head")
    -- utils.dump(content, "reqLogin")

    local account = content.account
    if account == "" then
        return {
            result = 1,
            errmsg = "账号为空",
        }
    end
    
    local password = content.password
    if password == "" then
        return {
            result = 2,
            errmsg = "密码为空",
        }
    end

    local result = skynet_db_call("login_account", account, password)
    utils.dump(result, "result")

    if not result then
        return {
            result = 3,
            errmsg = "未知错误",
        }
    end

    if #result.result == 0 then
        return {
            result = 4,
            errmsg = "用户不存在",
        }
    end

    -- 校验密码
    if result.result[1].password ~= content.password then
        return {
            result = 5,
            errmsg = "密码错误",
        }
    end

    -- 返回结果
    return {
        result = 0,
        userInfo = {
            userId = result.result[1].userId,
            score = result.result[1].score,
        },
        errmsg = "登录成功",
    }
end

return logic