local skynet = require("skynet")
local cjson = require("cjson")
local database = require("db_server.database.database")
require("common.export")

local logic = {
}

local userId_index = 10000

-- 请求注册
function logic.onReqRegist(dbconn, head, content)
    -- dump(head, "head")
    -- dump(content, "reqRegist")
    local reply = {
        result = 0,
        errmsg = "注册成功",
    }
    return reply
end

-- 请求登录
function logic.onReqLogin(dbconn, head, content)
    -- dump(head, "head")
    -- dump(content, "reqLogin")
    userId_index = userId_index + 1
    local reply = {
        result = 0,
        userInfo = {
            userId = userId_index,
            score = 1000,
        },
        errmsg = "登录成功",
    }
    return reply
end

-- 记录请求日志
function logic.onWriteLog(dbconn, head, content)
    assert(dbconn ~= nil)
    assert(content ~= nil)
    if dbconn == nil then
        return 1, "db is nil"
    end

    if content == nil then
        return 2, "content is nil"
    end

    skynet.error("请求日志")

    local data = cjson.decode(content)
    dump(data, "数据库·请求日志）")

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