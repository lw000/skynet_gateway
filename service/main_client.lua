package.path = ";./service/?.lua;" .. package.path
local skynet = require("skynet")
local conf = require("config.config")
require("common.export")

local function onStart()
    for i = 0, 10 do
        skynet.sleep(10)
        local client_id = skynet.newservice("ws_client")
        -- skynet.send(client_id, "lua", "start", "ws", string.format("%s:%d", "125.88.183.14", conf.gatePort))
        skynet.send(client_id, "lua", "start", "ws", string.format("%s:%d", "127.0.0.1", conf.gatePort))
    end
    skynet.exit()
end

skynet.start(onStart)
