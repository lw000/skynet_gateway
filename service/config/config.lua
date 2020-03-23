local config = {
    -- 中心服配置
    center = {
        -- 调试环境
        debug = true,
        -- 中心服debug端口
        debugPort = 8000,
        -- 中心服端口
        port = 9900,
    },

    -- 网关服配置
    gate = {
        -- 调试环境
        debug = false,
        -- 网关debug端口
        debugPort = 8001,
        -- 网关服务端口
        port = 9948,
        -- 中心服地址
        centerIP= "127.0.0.1",
        -- 中心服端口
        centerPort = 9900,
    },
    
    -- 聊天服
    chat = {
        -- 调试环境
        debug = false,
    },

    -- 大厅服
    lobby = {
        -- 调试环境
        debug = false,
    },
    
    -- db配置
    db = {
        -- 调试环境
        debug = false,

        host = "192.168.0.102",
        port = 3306,
        database = "test",
        user = "root",
        -- password = "LEvi123!",
        password = "lwstar",
    },
    --redis配置
    redis = {
        -- 调试环境
        debug = false,

        host = "127.0.0.1",
        port = 6379,
        db = 0,
    }
}

return config