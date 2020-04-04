package.path = ";./service/?.lua;" .. package.path
local skynet = require("skynet")
local cluster = require "skynet.cluster"
local conf = require("config.config")
require("common.export")

local function loadstring(chunk, chunkname)
    assert(chunk ~= nil)
    local env = {}
    return assert(load(chunk, chunkname, "t", env))() or env
end

local function onStart()
    skynet.error("加载配置文件..")
    local config = loadstring(skynet.getenv("config"), "@master.config")
    dump(config)
    skynet.error("配置文件加载完成")
    
    skynet.newservice("debug_console", config.debugPort)

    local service_id = skynet.newservice("master_service")
    skynet.call(service_id,"lua", "start")

    skynet.exit()
end

skynet.start(onStart)
