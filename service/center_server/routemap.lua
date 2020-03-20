require("service_config.cmd")
require("service_config.define")

-- 中心F路由转发映射表
local RouteMap = 
{
    [LOGON_CMD.MDM_LOGON] = {to = SERVICE_CONF.LOGON.NAME, desc = "登录服务"},
    [LOG_CMD.MDM_LOG] = {to = SERVICE_CONF.LOG.NAME, desc = "日志服务"}
}

return RouteMap