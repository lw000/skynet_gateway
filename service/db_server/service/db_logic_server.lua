local skynet = require("skynet")
local service = require("skynet.service")
local database = require("database.database")
local utils = require("utils")
require("skynet.manager")

local handler = {
    conn = nil,   -- db连接
    conf = nil,   -- 数据库配置
}

function handler.start(content)
    assert(content ~= nil)
    handler.conf = content.conf

    handler.conn = database.open(handler.conf)
    assert(handler.conn ~= nil)
    if handler.conn == nil then
        return 1, "db connect fail"
    end

    return 0
end

function handler.stop()
    database.close(handler.conn)
    handler.conn = nil

    skynet.exit()
    
    return 0
end

function handler.query(sql)
    local result, err = database.query(handler.conn, sql)
    if err ~= nil then
        return 1, err
    end
    return 0, result
end

function handler.execute(sql, ...)
    local result, err = database.execute(handler.conn, sql, ...)
    if err ~= nil then
        return 1, err
    end
    return 0, result
end

local function dispatch()
    skynet.dispatch(
        "lua",
        function(session, address, cmd, ...)
            local f = handler[cmd]
            assert(f)
            if session == 0 then
                f(...)
            else
                skynet.ret(skynet.pack(f(...)))
            end
        end
    )
    skynet.register(".db_logic_server")
end

skynet.start(dispatch)