local skynet = require("skynet")
local service = require("skynet.service")
local skyhelper = require("skycommon.helper")
local logic = require("service.chat_logic_func")
require("skynet.manager")
require("service_config.service_type")
require("proto_map.proto_map")

-- 业务处理接口映射表
local methods = {
    [CHAT_CMD.SUB.CHAT] = {func=logic.onChat, desc="聊天信息"}
}

local chat_server_id = -1

local CMD = {
    servername = ".chat_logic_server",
    debug = false,
}

function CMD.start(content)
    CMD.debug = content.debug
    chat_server_id = content.chat_server_id
    return 0
end

-- 服务停止·接口
function CMD.stop()
    skynet.exit()
    return 0
end

local function dispatch_send_message(head, content)
    assert(head ~= nil and type(head)== "table")
    assert(content ~= nil and type(content)== "table")
    
    if CMD.debug then
        skynet.error(string.format(CMD.servername .. ":> mid=%d sid=%d", head.mid, head.sid))
    end
 
    -- 查询业务处理函数
    local method = methods[head.sid]
    assert(method ~= nil)
    if not method then
        local errmsg = "unknown " .. CMD.servername .. " [sid=" .. tostring(head.sid) .. "] command"
        skynet.error(errmsg)
        return nil, errmsg
    end

    local ret, ack = proto_map.exec(head, content, method.func)
    if ret ~= 0 then
        skynet.error(ret, ack)
        return ack 
    end

    skyhelper.send(head.agent, "send_client_message", head, ack)
end

-- DB服务·消息处理接口
function CMD.dispatch_send_message(head, content)
    dispatch_send_message(head, content)
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