package.path = ";./service/?.lua;" .. package.path
local skynet = require("skynet")
local cluster = require "skynet.cluster"
local conf = require("config.config")
require("common.export")

local function onStart()
    cluster.reload {
        master = "0.0.0.0:2528",
    }
    cluster.open("master")
    skynet.newservice("master_service")
    
    skynet.exit()
end

skynet.start(onStart)
