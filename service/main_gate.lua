package.path = ";./service/?.lua;" .. package.path
local skynet = require("skynet")
local conf = require("config.config")
require("common.export")

local function onStart()
    local gate_server = skynet.uniqueservice("gate_server")
    local ret, err = skynet.call(gate_server, "lua", "start", conf.gatePort)
    if err then
        skynet.error(ret, err)
    end
    skynet.exit()
end

skynet.start(onStart)
