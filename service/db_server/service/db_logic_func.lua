local skynet = require("skynet")
local cjson = require("cjson")
local database = require("database.database")
local utils = require("utils")

local logic = {}

-- 注册账号
function logic.register_account(dbconn, service, content)
    utils.dump(content, "content")
    local reply = {
        result = 0,
        errmsg = "注册成功",
    }
    return reply
end

-- 登录账号
function logic.login_account(dbconn, service, content)
    utils.dump(content, "content")

    if content.account == "" then
        return {
            result = 1,
            errmsg = "账号为空",
        }
    end

    if content.password == "" then
        return {
            result = 2,
            errmsg = "密码为空",
        }
    end

    -- 查询用户信息
    local sql = [[select account, userId, score, password from user where account =?;]]
    local result, err = database.execute(dbconn, sql, content.account)
    if err ~= nil then
        return {
            result = 3,
            errmsg = "未知错误",
        }
    end
    utils.dump(result, "result")

    if #result == 0 then
        return {
            result = 4,
            errmsg = "用户不存在",
        }
    end

    -- 校验密码
    if result[1].password ~= content.password then
        return {
            result = 5,
            errmsg = "密码错误",
        }
    end

    -- 返回结果
    return {
        result = 0,
        userInfo = {
            userId = result[1].userId,
            score = result[1].score,
        },
        errmsg = "登录成功",
    }
end

-- 记录日志
function logic.writeLog(dbconn, service, content)
    local data = cjson.decode(content)
    utils.dump(data, "数据库·请求日志）")

    local sql = [[INSERT INTO reqLog (clientIp, content, updateTime) VALUES (?,?,?);]]
    local now = os.date("%Y-%m-%d %H:%M:%S", os.time())
    local result, err = database.execute(dbconn, sql, data.clientIp, data.content, now)
    if err ~= nil then
        skynet.error(err)
        return 3, err
    end

    return 0
end

return logic