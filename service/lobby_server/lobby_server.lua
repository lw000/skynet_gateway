local skynet = require("skynet")
local service = require("skynet.service")
local utils = require("utils")
local logic = require("lobby_logic")
local skyhelper = require("skycommon.helper")
require("skynet.manager")
require("service_type")
require("proto_map")

-- 业务处理接口映射表
local methods = {
    [LOBBY_CMD.SUB.REGIST] = {func=logic.onReqRegist, desc="请求登录"},
    [LOBBY_CMD.SUB.LOGON] = {func=logic.onReqLogin, desc="请求登录"},
}

local handler = {
	servicetype = SERVICE_TYPE.LOBBY.ID, 	-- 服务类型
    servername = SERVICE_TYPE.LOBBY.NAME,  	-- 服务名
    debug = false,
}

function handler.start(content)
    assert(content ~= nil, "content is nil")
    handler.debug = content.debug
    return 0
end

function handler.stop() 
    skynet.exit();
    return 0
end

local function dispatch_send_message(head, content)
    -- 查询业务处理函数
    local method = methods[head.sid]
    assert(method ~= nil)
    if not method then
        local errmsg = "unknown " .. handler.servername .. " [sid=" .. tostring(head.sid) .. "] command"
        skynet.error(errmsg)
        return
    end

    local ret, ack = proto_map.exec(head, content, method.func)
    if ret ~= 0 then
        skynet.error(ret, ack)
        return 
    end

    skyhelper.send(head.agent, "send_client_message", head, ack)
end

-- 登录服·消息处理接口
function handler.dispatch_send_message(head, content)
    if handler.debug then
        utils.dump(head, handler.servername .. ".head")
    end
	dispatch_send_message(head, content)
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
    skynet.register(handler.servername)
end

skynet.start(dispatch)
