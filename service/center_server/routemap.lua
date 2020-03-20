require("service_config.cmd")
require("service_config.type")

-- 中心F路由转发映射表
local RouteMap = 
{
    [LOGON_CMD.MDM_LOGON] = {to = SERVICE_TYPE.LOGON.NAME, desc = "登录服务"},
    [LOG_CMD.MDM_LOG] = {to = SERVICE_TYPE.LOG.NAME, desc = "日志服务"}
}

return RouteMap