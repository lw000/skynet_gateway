local skynet = require("skynet")
local cjson = require("cjson")
local database = require("db_server.database.database")
require("common.export")

local logic = {
}

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