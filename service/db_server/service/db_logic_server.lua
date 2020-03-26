package.path = package.path .. ";./service/?.lua;"
local skynet = require("skynet")
local service = require("skynet.service")
local skyhelper = require("skycommon.helper")
local database = require("db_server.database.database")
local mgr = require("db_server.service.db_logic_manager")
require("skynet.manager")
require("skynet.manager")
require("common.export")

local db_server_id = -1

local CMD = {
    servername = ".db_logic_server",
    dbconn = nil,                   -- db连接
    conf = nil,                     -- 数据库配置
    debug = false,
}

function CMD.start(content)
    assert(content ~= nil)
    CMD.debug = content.conf.debug
    CMD.conf = content.conf
    db_server_id = content.db_server_id

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

-- DB服务·send消息处理接口
function CMD.dispatch_call_message(head, content)
    return mgr.dispatch(CMD.dbconn, head, content)
end

-- DB服务·call消息处理接口
function CMD.dispatch_send_message(head, content)
    mgr.dispatch(CMD.dbconn, head, content)
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