local skynet = require("skynet")
local utils = require("utils")

local function loadstring(chunk, chunkname)
	assert(chunk ~= nil)
	local env = {}
	return assert(load(chunk, chunkname, "t", env))() or env
end

local function onStart()
    local config = loadstring(skynet.getenv("config"), "@gate.config")
    assert(config ~= nil)
    -- utils.dump(config, "config")

    skynet.newservice("debug_console", config.debugPort)

    -- 网关服
    local gate_server_id = skynet.newservice("gate_server")
    local ret, err = skynet.call(gate_server_id, "lua", "start", config)
    if err then
        skynet.error(ret, err)
        return
    end
    skynet.exit()
end

skynet.start(onStart)
