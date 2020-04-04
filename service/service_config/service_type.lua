require("dump")

---------------------------------------------------------------------------------------
-- 服务配置
SERVICE_TYPE = {
    GATE    =  { ID= 1, NAME= ".gate_server",      DESC= "网关服" },
    LOBBY   =  { ID= 2, NAME= ".lobby_server",     DESC= "大厅服" },
    CENTER  =  { ID= 3, NAME= ".center_server",    DESC= "中心服" },
    LOG     =  { ID= 4, NAME= ".log_server",      DESC= "日志服" },
    REDIS   =  { ID= 5, NAME= ".redis_server",    DESC= "缓存服务器" },
    DB      =  { ID= 6, NAME= ".db_server",       DESC= "数据服务器" },
    CHAT    =  { ID= 7, NAME= ".chat_server",       DESC= "聊天服务器" },
}

-- dump(SERVICE_TYPE, "SERVICE_TYPE")