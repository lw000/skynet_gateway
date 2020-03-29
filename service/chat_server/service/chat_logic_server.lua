package.path = package.path .. ";./service/?.lua;"
local skynet = require("skynet")
local service = require("skynet.service")
local skyhelper = require("skycommon.helper")
local mgr = require("chat_server.service.chat_manager")
require("skynet.manager")

local CMD = {

}

local chat_server_id = -1

local CMD = {
    servername = ".chat_logic_server",
    debug = false,
}

function CMD.start(content)
    CMD.debug = content.debug
    chat_server_id = content.chat_server_id

    mgr.start(CMD.servername, CMD.debug)

    return 0
end

-- 服务停止·接口
function CMD.stop()
    mgr.stop()

    return 0
end

-- DB服务·消息处理接口
function CMD.dispatch_send_message(head, content)
    mgr.dispatch(head, content)
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