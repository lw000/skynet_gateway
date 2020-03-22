package.path = ";./service/?.lua;" .. package.path
local skynet = require("skynet")
local conf = require("config.config")
require("common.export")

local function onStart()
     -- 网关服
    local gate_server_id = skynet.newservice("gate_server")
    local ret, err = skynet.call(gate_server_id, "lua", "start", 
    {
        port = conf.gatePort,
        centerPort = conf.centerPort,
    })
    if err then
        skynet.error(ret, err)
        return
    end
    skynet.exit()
end

skynet.start(onStart)
