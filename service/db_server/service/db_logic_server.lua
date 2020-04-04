local skynet = require("skynet")
local service = require("skynet.service")
local skyhelper = require("helper")
local database = require("database.database")
local logic = require("service.db_logic_func")
require("skynet.manager")
require("utils")

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

    return 0
end

-- 服务停止·接口
function CMD.stop()
    database.close(CMD.dbconn)
    CMD.dbconn = nil
    return 0
end

local function dispatch_message(command, service, ...) 
    -- 查询业务处理函数
    local f = logic[command]
    assert(f ~= nil)
    if not f then
        local errmsg = string.format( "unknown %s command=%s", CMD.servername, command )
        skynet.error(errmsg)
        return
    end
    return f(CMD.dbconn, service, ...)
end

-- DB服务·send消息处理接口
function CMD.dispatch_call_message(command, service, ...)
    return dispatch_message(command, service, ...)
end

-- DB服务·call消息处理接口
function CMD.dispatch_send_message(command, ...)
    dispatch_message(command, nil, ...)
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