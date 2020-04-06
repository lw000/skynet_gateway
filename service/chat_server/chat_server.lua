local skynet = require("skynet")
local service = require("skynet.service")
local skyhelper = require("helper")
local utils = require("utils")
require("skynet.manager")
require("service_type")

local chat_logic_servers = {}  -- 服务ID

local function get_chat_logic_servers(agent)
    local index = (agent % #chat_logic_servers)+1
    -- skynet.error("chat_logic_servers index:", index)
    local chat_logic_server = chat_logic_servers[index]
    return chat_logic_server
end

local function dispatch_send_message(head, content)
    skyhelper.send(get_chat_logic_servers(head.center_agent), "dispatch_send_message", head, content)
end

local handler = {
    servicetype = SERVICE_TYPE.CHAT.ID, 	-- 服务类型
	servername = SERVICE_TYPE.CHAT.NAME,  	-- 服务名
    debug = false,
}

function handler.start(content)
    assert(content ~= nil, "content is nil")
    math.randomseed(os.time())

    handler.debug = content.debug

    for i=1, 10 do
        local chat_logic_server = skynet.newservice("service/chat_logic_server")
        chat_logic_servers[i] = chat_logic_server
        skynet.call(chat_logic_server, "lua", "start", {
            debug = handler.debug,
            chat_server_id = skynet.self(),
        })
    end
    -- utils.dump(chat_logic_servers, "chat_logic_servers")

    return 0
end

function handler.stop()
    skynet.exit();
    return 0
end

-- 聊天服·消息处理接口
function handler.dispatch_send_message(head, content)
    -- utils.dump(head, "head")
    -- utils.dump(content, "content")
    return dispatch_send_message(head, content)
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
