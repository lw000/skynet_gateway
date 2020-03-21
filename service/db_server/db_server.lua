package.path = package.path .. ";./service/?.lua;"
local skynet = require("skynet")
local service = require("skynet.service")
local database = require("db_server.database.database")
local dbmgr = require("db_server.manager")
require("skynet.manager")
require("common.export")
require("service_config.type")
require("service_config.cmd")

--[[
    db数据库服务
]]

local command = {
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
function command.START(conf)
    assert(conf ~= nil)
    
    -- 设置随机种子
    math.randomseed(os.time())

    command.conf = conf
    command.dbconn = database.open(command.conf)
    assert(command.dbconn ~= nil)
    if command.dbconn == nil then
        return 1, command.servername .. " fail"
    end

    dbmgr.start(command.servername)
    return 0
end

-- 服务停止·接口
function command.STOP()

    dbmgr.stop()
    
    database.close(command.dbconn)
    command.dbconn = nil
    return 0
end

-- DB服务·消息处理接口
function command.MESSAGE(head, content)
    assert(head ~= nil and type(head)== "table")
    assert(content ~= nil and type(content)== "table")
    return dbmgr.dispatch(command.dbconn, head, content)
end

local function dispatch()
    skynet.dispatch(
        "lua",
        function(session, address, cmd, ...)
            cmd = cmd:upper()
            local f = command[cmd]
            assert(f)
            if f then
                skynet.ret(skynet.pack(f(...)))
            else
                skynet.error(string.format(command.servername .. " unknown command %s", tostring(cmd)))
            end
        end
    )
    skynet.register(command.servername)
end

skynet.start(dispatch)
