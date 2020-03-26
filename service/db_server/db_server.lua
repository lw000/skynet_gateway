package.path = package.path .. ";./service/?.lua;"
local skynet = require("skynet")
local service = require("skynet.service")
local skyhelper = require("skycommon.helper")
require("skynet.manager")
require("common.export")
require("service_config.type")
require("service_config.cmd")


local db_logic_servers = {}  -- 服务ID

--[[
    db数据库服务
]]
local CMD = {
    servertype = SERVICE_TYPE.DB.ID,   -- 服务类型
    servername = SERVICE_TYPE.DB.NAME,   -- 服务名
    debug = false,
}

-- 服务启动·接口
--[[
    返回值：code, err
    code=0成功，非零失败
    err 错误消息
]]
function CMD.start(conf)
    assert(conf ~= nil)
    
    CMD.debug = conf.debug
    if CMD.debug then
        dump(conf, "conf")
    end

    -- 设置随机种子
    math.randomseed(os.time())

    for i=1, 10 do
        local db_logic_server = skynet.newservice("service/db_logic_server")
        db_logic_servers[i] = db_logic_server
        skynet.call(db_logic_server, "lua", "start", {
            conf = conf,
            db_server_id = skynet.self(),
        })
    end
    -- dump(db_logic_servers, "db_logic_servers")

    return 0
end

-- 服务停止·接口
function CMD.stop()
    return 0
end

-- DB服务·send消息处理接口
function CMD.dispatch_send_message(mid, sid, service, content)
    local index = math.random(1,10)
    if CMD.debug then
        dump(content, CMD.servername .. ".content")
        skynet.error("db_logic_server rand index:", index)
    end
    
    skyhelper.send(db_logic_servers[index], "dispatch_send_message", mid, sid, service, content)
end

-- DB服务·call消息处理接口
function CMD.dispatch_call_message(mid, sid, service, content)
    local index = math.random(1,10)
    if CMD.debug then
        dump(content, CMD.servername .. ".content")
        skynet.error("db_logic_server rand index:", index)
    end
    return skyhelper.call(db_logic_servers[index], "dispatch_call_message", mid, sid, service, content)
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
