package.path = ";./service/?.lua;" .. package.path
local skynet = require("skynet")
local conf = require("config.config")
require("common.export")

local function onStart()
    skynet.newservice("debug_console", conf.centerDebugPort)
    
    -- DB服务
    local db_server_id = skynet.newservice("db_server")
    local ret, err = skynet.call(db_server_id, "lua", "start", conf.db)
    if err then
        skynet.error(ret, err)
        return
    end

    -- 大厅服务
    local lobby_server_id = skynet.newservice("lobby_server")
    local ret, err = skynet.call(lobby_server_id, "lua", "start")
    if err then
        skynet.error(ret, err)
        return
    end

    -- 聊天服务
    local chat_server_id = skynet.newservice("chat_server")
    local ret, err = skynet.call(chat_server_id, "lua", "start")
    if err then
        skynet.error(ret, err)
        return
    end

    -- 中心F
    local center_server_id = skynet.newservice("center_server")
    local ret, err = skynet.call(center_server_id, "lua", "start", 
    {
        port = conf.centerPort,
    })
    if err then
        skynet.error(ret, err)
        return
    end

    skynet.exit()
end

skynet.start(onStart)
