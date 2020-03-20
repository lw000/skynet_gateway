require("common.export")

-- 服务内部协议指令
-------------------------------------------------------------------------------------
----- 登录服·命令
LOGON_CMD = {
    MDM_LOGON = 0x0002,   -- 登录服·主命令
    SUB = {
        LOGON = 0x0001,   -- 请求登录
        CHAT = 0x0002,    -- 聊天消息
    }
}

----- 中心服·命令
CENTER_CMD = {
    MDM_CENTER = 0x0003,    -- 中心F服·主命令
}

-- 日志服·命令
LOG_CMD = {
    MDM_LOG = 0x0003,       -- 日志服·主命令
    SUB = {
        LOG = 0x0001,       -- 请求日志
    }
}

-- dump(LOG_CMD, "LOG_CMD")
-- dump(CENTER_CMD, "CENTER_CMD")
-- dump(LOGON_CMD, "LOGON_CMD")