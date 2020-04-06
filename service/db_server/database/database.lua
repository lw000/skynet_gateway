local skynet = require("skynet")
local mysql = require("skynet.db.mysql")
local utils = require("utils")

-- conf = {
--     host = "",      -- 主机地址
--     port = 3306,    -- 端口
--     database = "",  -- 数据库名
--     user = "",      -- 数据库用户名
--     password = "",  -- 数据库密码
-- }

local database = {}

local function on_connect(db)
    db:query("set charset utf8mb4")
end

-- 打开数据库连接
function database.open(conf)
    assert(conf ~= nil)

    local opts = {
        host = conf["host"] or "127.0.0.1",
        port = conf["port"]  or 3306,
        database = conf["database"],
        user = conf["user"],
        password = conf["password"],
        max_packet_size = 1024 * 1024,
        on_connect = on_connect
    }
    
    local db = mysql.connect(opts)
    assert(db ~= nil)
    if not db then
        skynet.error("failed to connect gamedata")
        return nil
    end
    return db
end

-- 关闭数据库连接
function database.close(dbconn)
    if dbconn then
        dbconn:disconnect()
    end
end

-- 查询sql
function database.query(dbconn, sql)
    skynet.error("database.query:", sql)

    local results = dbconn:query(sql)
    if results.err then
        skynet.error("error: sql execute, " .. results.err)
        return nil, results.err
    end
    
    -- utils.dump(results)

    return results
end

-- 执行sql
function database.execute(dbconn, sql, ...)
    skynet.error("database.execute:", sql, ...)
    local stmt = dbconn:prepare(sql)
    if stmt.err then
        skynet.error("error: sql prepare, " .. stmt.err)
        return nil, stmt.err
    end
    local results = dbconn:execute(stmt, ...)
    dbconn:stmt_close(stmt)
    if results.err then
        skynet.error("error: sql execute, " .. results.err)
        return nil, results.err
    end
    
    -- utils.dump(results)

    return results
end

function database.ping(dbconn)
    return dbconn:ping()
end

return database