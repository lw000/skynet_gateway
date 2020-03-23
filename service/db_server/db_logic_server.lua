package.path = package.path .. ";./service/?.lua;"
local skynet = require("skynet")
local service = require("skynet.service")
local skyhelper = require("skycommon.helper")
local database = require("db_server.database.database")
local mgr = require("db_server.db_manager")
require("skynet.manager")
require("common.export")

local db_server_id = -1

local CMD = {
    servername = ".db_logic_server",
    dbconn = nil,                   -- db连接
    conf = nil,                     -- 数据库配置
    debug = false,
}

function CMD.start(conf)
    assert(conf ~= nil)
    CMD.debug = conf.conf.debug
    CMD.conf = conf.conf
    db_server_id = conf.db_server_id

    CMD.dbconn = database.open(CMD.conf)
    assert(CMD.dbconn ~= nil)
    if CMD.dbconn == nil then
        return 1, CMD.servername .. " db connect fail"
    end

    mgr.start(CMD.servername, CMD.debug)

    return 0
end

-- 服务停止·接口
function CMD.stop()
    mgr.stop()

    database.close(CMD.dbconn)
    CMD.dbconn = nil
    return 0
end

-- DB服务·消息处理接口
function CMD.server_message(head, content)
    assert(head ~= nil and type(head)== "table")
    assert(content ~= nil and type(content)== "table")
    return mgr.dispatch(CMD.dbconn, head, content)
end

-- 请求注册
function CMD.onReqRegist(dbconn, head, content)
    -- dump(head, "head")
    -- dump(content, "reqRegist")
    local reply = {
        result = 0,
        errmsg = "注册成功",
    }
    return reply
end


local userId_index = 10000

-- 请求登录
function CMD.onReqLogin(dbconn, head, content)
    -- dump(head, "head")
    -- dump(content, "reqLogin")
    userId_index = userId_index + 1
    local reply = {
        result = 0,
        userInfo = {
            userId = userId_index,
            score = 1000,
        },
        errmsg = "登录成功",
    }
    return reply
end

-- 记录请求日志
function CMD.onWriteLog(dbconn, head, content)
    assert(dbconn ~= nil)
    assert(content ~= nil)
    if dbconn == nil then
        return 1, "db is nil"
    end

    if content == nil then
        return 2, "content is nil"
    end

    skynet.error("请求日志")

    local data = cjson.decode(content)
    dump(data, "数据库·请求日志）")

    local sql = [[INSERT INTO reqLog (clientIp, content, updateTime) VALUES (?,?,?);]]
    local now = os.date("%Y-%m-%d %H:%M:%S", os.time())
    local result, err = database.execute(dbconn, sql, data.clientIp, data.content, now)
    if err ~= nil then
        skynet.error(err)
        return 3, err
    end

    return 0
end

local function dispatch()
    skynet.dispatch(
        "lua",
        function(session, address, cmd, ...)
            local f = CMD[cmd]
            assert(f)
            if session == 0 then
                f(...)
            else
                skynet.ret(skynet.pack(f(...)))
            end
        end
    )
    skynet.register(CMD.servername)
end

skynet.start(dispatch)