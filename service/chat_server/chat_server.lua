package.path = package.path .. ";./service/?.lua;"
local skynet = require("skynet")
local service = require("skynet.service")
local skyhelper = require("skycommon.helper")
require("skynet.manager")
require("common.export")
require("service_config.type")


local chat_logic_servers = {}  -- 服务ID

local CMD = {
    servicetype = SERVICE_TYPE.CHAT.ID, 	-- 服务类型
	servername = SERVICE_TYPE.CHAT.NAME,  	-- 服务名
    debug = false,
}

function CMD.start(content)
    math.randomseed(os.time())

    CMD.debug = content.debug

    for i=0, 9 do
        local chat_logic_server = skynet.newservice("service/chat_logic_server")
        chat_logic_servers[i] = chat_logic_server
        skynet.call(chat_logic_server, "lua", "start", {
            debug = CMD.debug,
            chat_server_id = skynet.self(),
        })
    end
    -- dump(chat_logic_servers, "chat_logic_servers")

    return 0
end

function CMD.stop() 
    return 0
end

-- 登录服·消息处理接口
function CMD.on_server_message(head, content)
    assert(head ~= nil and type(head)== "table")
    assert(content ~= nil and type(content)== "table")

    -- dump(head, "head")

    local index = head.serviceId % (#chat_logic_servers+1)

    -- skynet.error("rand chat_logic_server index:", index)
    local chat_logic_server = chat_logic_servers[index]
    return skyhelper.call(chat_logic_server, "on_server_message", head, content)
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
