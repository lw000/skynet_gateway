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

-- 服务内部协议指令
-------------------------------------------------------------------------------------
----- 登录服·命令
LOGON_CMD = {
    MDM_LOGON = 0x0002,                         -- 登录服·主命令
    SUB = {
        LOGON = 0x0001,                         -- 请求登录
        CHAT = 0x0002,                          -- 聊天消息
    }
}

----- 中心服·命令
CENTER_CMD = {
    MDM_CENTER = 0x0003,                        -- 中心F服·主命令
}

-- 日志服·命令
LOG_CMD = {
    MDM_LOG = 0x0003,                           -- 日志服·主命令
    SUB_LOG = 0x0001,                           -- 请求日志
}

-- dump(LOG_CMD, "LOG_CMD")
-- dump(CENTER_CMD, "CENTER_CMD")
-- dump(SERVICE_CONF, "SERVICE_CONF")