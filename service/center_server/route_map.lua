require("core.define")

-- 中心F路由转发映射表配置
local RouteForwardMap = 
{
    [LOGON_CMD.MDM_LOGON] = {TO=SERVICE_CONF.LOGON.NAME, DESC="登录服务"},
    [LOG_CMD.MDM_LOG] = {TO=SERVICE_CONF.LOG.NAME, DESC="日志服务"}
}

return RouteForwardMap