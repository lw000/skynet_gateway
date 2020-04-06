local skynet = require("skynet")
local service = require("skynet.service")
local skyhelper = require("helper")
local utils = require("utils")
local cjson = require("cjson")
require("service_config.service_type")
require("service_config.service_cmd")
require("skynet.manager")

local db_logic_servers = {}  -- 数据库逻辑服务

--[[
    db数据库服务
]]

local handler = {
    servertype = SERVICE_TYPE.DB.ID,        -- 服务类型
    servername = SERVICE_TYPE.DB.NAME,      -- 服务名
    debug = false,
}

-- 服务启动·接口
function handler.start(conf)
    assert(conf ~= nil, "conf is nil")
    handler.debug = conf.debug

    for i=1, 10 do
        local db_logic_server = skynet.newservice("service/db_logic_server")
        db_logic_servers[i] = db_logic_server
        skynet.call(db_logic_server, "lua", "start", {
            conf = conf,
        })
    end

    return 0
end

-- 服务停止·接口
function handler.stop()
    for i, v in ipairs(db_logic_servers) do
        skynet.call(v, "lua", "stop")
    end
    skynet.exit();
    return 0
end

local function get_db_logic_server()
    local index = math.random(1,10)
    return db_logic_servers[index]
end

local function skynet_call_db_query(sql)
    return skyhelper.call(get_db_logic_server(), "query",sql)
end

local function skynet_call_db_execute(sql, ...)
    return skyhelper.call(get_db_logic_server(), "execute", sql, ...)
end

local function skynet_send_db_query(sql)
    skyhelper.send(get_db_logic_server(), "query",sql)
end

local function skynet_send_db_execute(sql, ...)
    return skyhelper.call(get_db_logic_server(), "execute", sql, ...)
end

-- 注册账号
function handler.register_account(account, password)
    if account == "" then
        return {
            errcode = 1,
            errmsg = "账号为空",
        }
    end
    
    if password == "" then
        return {
            errcode = 2,
            errmsg = "密码为空",
        }
    end

    return {
        errcode = 0,
        errmsg = "",
    }
end

-- 登录账号
function handler.login_account(account, password)
    if account == "" then
        return {
            errcode = 1,
            errmsg = "账号为空",
        }
    end
    
    if password == "" then
        return {
            errcode = 2,
            errmsg = "密码为空",
        }
    end

    -- 查询用户信息
    local sql = [[SELECT account, userId, score, password FROM user WHERE account =?;]]
    local suc, result = skynet_call_db_execute(sql, account)
    if suc ~= 0 then
        return {
            errcode = 3,
            errmsg = "未知错误",
        }
    end

    -- 返回结果
    return {
        errcode = 0,
        errmsg = "",
        result = result,
    }
end

-- 记录日志
function handler.writeLog(content)
    local data = cjson.decode(content)
    -- utils.dump(data, "数据库·请求日志）")

    local sql = [[INSERT INTO reqLog (clientIp, content, updateTime) VALUES (?,?,?);]]
    local now = os.date("%Y-%m-%d %H:%M:%S", os.time())
    local suc, result = skynet_call_db_execute(sql, data.clientIp, data.content, now)
    if suc ~= 0 then
        return {
            errcode = 3,
            errmsg = "未知错误",
        }
    end

    return {
        errcode = 0,
        errmsg = "",
    }
end

local function dispatch()
    skynet.dispatch(
        "lua",
        function(session, address, cmd, ...)
            local f = handler[cmd]
            assert(f)
            if f then     
                if session == 0 then
                    f(...)
                else
                    skynet.ret(skynet.pack(f(...)))
                end
            end
        end
    )
    skynet.register(handler.servername)
end

skynet.start(dispatch)
