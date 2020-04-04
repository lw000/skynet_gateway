package.path = ";./service/?.lua;" .. package.path
local skynet = require("skynet")
local conf = require("config.config")
require("utils")

local function onStart()
    skynet.newservice("debug_console", conf.center.debugPort)
    
    -- DB服务
    local db_server_id = skynet.newservice("db_server")
    local ret, err = skynet.call(db_server_id, "lua", "start", conf.db)
    if err then
        skynet.error(ret, err)
        return
    end

    -- 大厅服务
    local lobby_server_id = skynet.newservice("lobby_server")
    local ret, err = skynet.call(lobby_server_id, "lua", "start", conf.lobby)
    if err then
        skynet.error(ret, err)
        return
    end

    -- 聊天服务
    local chat_server_id = skynet.newservice("chat_server")
    local ret, err = skynet.call(chat_server_id, "lua", "start", conf.chat)
    if err then
        skynet.error(ret, err)
        return
    end

    -- 中心F
    local center_server_id = skynet.newservice("center_server")
    local ret, err = skynet.call(center_server_id, "lua", "start", conf.center)
    if err then
        skynet.error(ret, err)
        return
    end

    -- local sessions = {}
    -- sessions[1] = {a=1, b=1}
    -- sessions[2] = {a=2, b=2}
    -- sessions[3] = {a=3, b=3}
    -- sessions[4] = {a=4, b=4}
    -- dump(sessions, "sessions")
    -- sessions[2] = nil
    -- sessions[3] = nil
    -- dump(sessions, "sessions")

    -- local users = {{0,1},{1,2},{2,3},{3,4},{4,5},{5,6},{6,7},{7,8},{8,9}}
    -- users = shuffle(users)
    -- dump(users, "users")

    skynet.exit()
end

skynet.start(onStart)
