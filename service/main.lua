package.path = ";./service/?.lua;" .. package.path
local skynet = require("skynet")
local conf = require("config.config")
require("common.export")

-- local pack_little = string.pack("<I2", 259)
-- local pack_bigger = string.pack(">I2", 259)
-- print(
--     "pack_little = " .. pack_little .. " byte1 = " .. pack_little:byte(1) .. " byte2 = " .. pack_little:byte(2)
-- )
-- print(
--     "pack_bigger = " .. pack_bigger .. " byte1 = " .. pack_bigger:byte(1) .. " byte2 = " .. pack_bigger:byte(2)
-- )

local function onStart()
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

    -- 网关服
    local gate_server_id = skynet.newservice("gate_server")
    local ret, err = skynet.call(gate_server_id, "lua", "start", conf.gate)
    if err then
        skynet.error(ret, err)
        return
    end

    -- 模拟客户端
    for i = 1, 1 do
        skynet.sleep(10)
        local client_id = skynet.newservice("robot_server")
        skynet.send(client_id, "lua", "start", "ws", string.format("%s:%d", "127.0.0.1", conf.gate.port), {
            account=string.format("%s_%d", "levi", i),
            password="123456"
        })
    end
    
    skynet.exit()
end

skynet.start(onStart)
