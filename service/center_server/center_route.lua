require("service_config.service_cmd")
require("service_config.service_type")

-- 中心F路由转发映射表
local BackendRoute = 
{
    [CENTER_CMD.MDM] = {name = SERVICE_TYPE.CENTER.NAME, desc = "中心服务"},
    [LOBBY_CMD.MDM] = {name = SERVICE_TYPE.LOBBY.NAME, desc = "大厅服务"},
    [LOG_CMD.MDM]   = {name = SERVICE_TYPE.LOG.NAME, desc = "日志服务"},
    [DB_CMD.MDM]    = {name = SERVICE_TYPE.DB.NAME, desc = "DB服务"},
    [REDIS_CMD.MDM] = {name = SERVICE_TYPE.REDIS.NAME, desc = "REDIS服务"},
    [CHAT_CMD.MDM] = {name = SERVICE_TYPE.CHAT.NAME, desc = "聊天服务"},
}

return BackendRoute