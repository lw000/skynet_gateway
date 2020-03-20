package.path = ";./service/?.lua;" .. package.path
local skynet = require("skynet")
local conf = require("config.config")
require("common.export")

local function onStart()
    skynet.newservice("debug_console", conf.debugPort)
    local center_server = skynet.uniqueservice("center_server")
    local ret, err = skynet.call(center_server, "lua", "start", conf.centerPort)
    if err then
        skynet.error(ret, err)
    end
    skynet.exit()
end

skynet.start(onStart)
