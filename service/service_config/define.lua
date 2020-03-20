require("common.export")

---------------------------------------------------------------------------------------
-- 服务配置
SERVICE_CONF = {
    GATE    =  { TYPE= 1, NAME= ".gate_server",      DESC= "网关服" },
    LOGON   =  { TYPE= 2, NAME= ".logon_server",     DESC= "登录服" },
    CENTER  =  { TYPE= 3, NAME= ".center_server",    DESC= "中心服" },
    LOG     =  { TYPE= 4, NAME= ".log_server",      DESC= "日志服" },
    REDIS   =  { TYPE= 5, NAME= ".redis_server",    DESC= "缓存服务器" },
    DB      =  { TYPE= 6, NAME= ".db_server",       DESC= "数据服务器" },
    CHAT    =  { TYPE= 7, NAME= ".chat_server",       DESC= "聊天服务器" },
}

-- dump(SERVICE_CONF, "SERVICE_CONF")