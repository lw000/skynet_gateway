package.path = package.path .. ";./service/?.lua;"
local skynet = require("skynet")
local service = require("skynet.service")
local database = require("db_server.database.database")
local mgr = require("db_server.manager")
require("skynet.manager")
require("common.export")
require("service_config.type")
require("service_config.cmd")

--[[
    db数据库服务
]]

local CMD = {
    servertype = SERVICE_TYPE.DB.ID,   -- 服务类型
    servername = SERVICE_TYPE.DB.NAME,   -- 服务名
    dbconn = nil,                   -- db连接
    conf = nil,                     -- 数据库配置
}

-- 服务启动·接口
--[[
    返回值：code, err
    code=0成功，非零失败
    err 错误消息
]]
function CMD.START(conf)
    assert(conf ~= nil)
    
    -- 设置随机种子
    math.randomseed(os.time())

    CMD.conf = conf
    CMD.dbconn = database.open(CMD.conf)
    assert(CMD.dbconn ~= nil)
    if CMD.dbconn == nil then
        return 1, CMD.servername .. " fail"
    end

    mgr.start(CMD.servername)
    return 0
end

-- 服务停止·接口
function CMD.STOP()
    mgr.stop()

    database.close(CMD.dbconn)
    CMD.dbconn = nil
    return 0
end

-- DB服务·消息处理接口
function CMD.MESSAGE(head, content)
    assert(head ~= nil and type(head)== "table")
    assert(content ~= nil and type(content)== "table")
    return mgr.dispatch(CMD.dbconn, head, content)
end

local function dispatch()
    skynet.dispatch(
        "lua",
        function(session, address, cmd, ...)
            cmd = cmd:upper()
            local f = CMD[cmd]
            assert(f)
            if f then
                skynet.ret(skynet.pack(f(...)))
            else
                skynet.error(string.format(CMD.servername .. " unknown CMD %s", tostring(cmd)))
            end
        end
    )
    skynet.register(CMD.servername)
end

skynet.start(dispatch)
