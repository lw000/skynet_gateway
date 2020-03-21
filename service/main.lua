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
    skynet.newservice("debug_console", conf.debugPort)

     -- 登录服务
     local logon_server_id = skynet.newservice("logon_server")
     local ret, err = skynet.call(logon_server_id, "lua", "start")
     if err then
         skynet.error(ret, err)
         return
     end

    -- 中心F
    local center_server_id = skynet.newservice("center_server")
    local ret, err = skynet.call(center_server_id, "lua", "start", 
    {
        logon_server_id = logon_server_id
    })
    if err then
        skynet.error(ret, err)
        return
    end

    -- 网关服
    local gate_server_id = skynet.newservice("gate_server")
    local ret, err = skynet.call(gate_server_id, "lua", "start", 
    {
        port = conf.gatePort,
        center_server_id = center_server_id,
    })
    if err then
        skynet.error(ret, err)
        return
    end

    -- 模拟客户端
    -- for i = 0, 0 do
    --     skynet.sleep(10)
    --     local client_id = skynet.newservice("ws_client")
    --     skynet.send(client_id, "lua", "start", "ws", string.format("%s:%d", "127.0.0.1", conf.gatePort))
    -- end
    
    skynet.exit()
end

skynet.start(onStart)
