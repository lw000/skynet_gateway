local skynet = require("skynet")
local conf = require("config.config")
local utils = require("utils")

local function onStart()
    for i = 1,10 do
        skynet.sleep(10)
        local client_id = skynet.newservice("robot_server")
        -- skynet.send(client_id, "lua", "start", "ws", string.format("%s:%d", "125.88.183.14", conf.gate.port))
        skynet.send(client_id, "lua", "start", "ws", string.format("%s:%d", "127.0.0.1", conf.gate.port), {
            account=string.format("%s%d", "test", i),
            password="123456"
        })
    end
    skynet.exit()
end

skynet.start(onStart)
