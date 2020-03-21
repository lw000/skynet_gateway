require("service_config.cmd")
require("service_config.type")

-- 中心F路由转发映射表
local Route = 
{
    [LOGON_CMD.MDM] = {name = SERVICE_TYPE.LOGON.NAME, desc = "登录服务"},
    [LOG_CMD.MDM]   = {name = SERVICE_TYPE.LOG.NAME, desc = "日志服务"},
    [DB_CMD.MDM]    = {name = SERVICE_TYPE.DB.NAME, desc = "DB服务"},
    [REDIS_CMD.MDM] = {name = SERVICE_TYPE.REDIS.NAME, desc = "REDIS服务"},
}

return Route