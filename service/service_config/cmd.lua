require("common.export")

-- 服务内部协议指令
-------------------------------------------------------------------------------------
----- 大厅服·命令
LOBBY_CMD = {
    MDM = 0x0002,     -- 大厅服·主命令
    SUB = {
        REGIST = 0x0001,    -- 请求注册
        LOGON = 0x0002,     -- 请求登录
        CHAT = 0x0003,      -- 聊天消息
    }
}

----- 中心服·命令
CENTER_CMD = {
    MDM = 0x0003,    -- 中心F服·主命令
    SUB = {
        REGIST = 0x0001,     -- 注册服务
        UNREGIST = 0x0002,   -- 卸载服务
    }
}

-- 日志服·命令
LOG_CMD = {
    MDM = 0x0004,       -- 日志服·主命令
    SUB = {
        LOG = 0x0001,       -- 请求日志
    }
}

----- REDIS服·命令
REDIS_CMD = {
    MDM = 0x0005,     -- REDIS服·主命令
    SUB = {
    }
}

----- DB服·命令
DB_CMD = {
    MDM = 0x0006,        -- DB服·主命令
    SUB = {
        REGIST = 0x0001,    -- 请求注册
        LOGON = 0x0002,     -- 请求登录
        LOG = 0x0003,       -- 日志消息
    }
}

----- 聊天服·命令
CHAT_CMD = {
    MDM = 0x0007,     -- 聊天服·主命令
    SUB = {
        CHAT = 0x0003,      -- 聊天消息
    }
}

-- dump(DB_CMD, "DB_CMD")
-- dump(REDIS_CMD, "REDIS_CMD")
-- dump(LOG_CMD, "LOG_CMD")
-- dump(CENTER_CMD, "CENTER_CMD")
-- dump(LOGON_CMD, "LOGON_CMD")