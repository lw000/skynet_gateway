local skynet = require("skynet")
local cjson = require("cjson")
local skyhelper = require("skycommon.helper")
require("common.export")
require("core.define")

local rediskey_web_server = "web_server"

local logic = {

}

-- 记录请求日志
function logic.onWriteLog(redisConn, content)
    local jsonstr = cjson.encode(content)
    skynet.error("REDIS·更新请求日志 " .. jsonstr)
    local ok = redisConn:hset(rediskey_web_server, content.clientIp, jsonstr)
    return ok
end

return logic