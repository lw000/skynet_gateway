local config = {
    -- 调试环境
    debug = true,
    -- 中心服debug端口
    centerDebugPort = 8000,
    -- 中心服端口
    centerPort = 9900,
    -- 网关debug端口
    gateDebugPort = 8001,
    -- 网关服务端口
    gatePort = 9948,
    -- db配置
    db = {
        host = "192.168.0.102",
        port = 3306,
        database = "test",
        user = "root",
        -- password = "LEvi123!",
        password = "lwstar",
    },
    --redis配置
    redis = {
        host = "127.0.0.1",
        port = 6379,
        db = 0,
    }
}

return config