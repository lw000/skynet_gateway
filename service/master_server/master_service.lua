package.path = package.path .. ";./service/?.lua;"
local skynet = require("skynet")
local socket = require("skynet.socket")
local service = require("skynet.service")
local cluster = require("skynet.cluster")
local skyhelper = require("skycommon.helper")
require("skynet.manager")

-- 注册网关列表
local gate_list = {}

local function gate_call(svrid,command,...)
    for k,v in pairs(gate_list) do
        if v.svrid == svrid then
            return pcall(skynet.call,v.service,"lua",command,...)
        end
    end
end

local function gate_send(svrid,command,...)
	for k,v in pairs(gate_list) do
        if v.svrid == svrid then
            pcall(skynet.send,v.service,"lua",command,...)
        end
    end
end

local function gate_broadcast(command,...)
    for k,v in pairs(gate_list) do
        pcall(skynet.send,v.service,"lua",command,...)
    end
end

local handler = {}

function handler.get(key)
    return key
end

function handler.get_gate_config(svrid)
    skynet.error("svrid=", svrid)
    local config = {}
    config.cluster = {
        name="gate1",
        addr="127.0.0.1:9999",
    }
    return config
end

function handler.register_gate(info)
    skynet.error("register_gate:",info.svrid,info.cluster.name,info.cluster.addr,info.service)
    local gate_info = gate_list[info.svrid]
    if gate_info then
        return gate_info.service
    else
		-- 注册节点
		cluster.reload({[info.cluster.name] = info.cluster.addr})
		-- 建立连接
		local service = skynet.newservice("master_proxy")
        skynet.call(service,"lua","open", info)
        local reg_info = {
            svrid = id,
            cluster = info.cluster,
            service = service,
        }
        gate_list[info.cluster.name] = reg_info
        return service
    end
end

skynet.init(
    function()
        skynet.register(".master_service")
    end
)

local function dispatch()
    skynet.dispatch(
        "lua",
        function(session, address, cmd, ...)
            skynet.error("master_service recved:",session, address, cmd, ...)
            local f = handler[cmd]
            assert(f)
            if session == 0 then
                f(...)
            else
                skynet.ret(skynet.pack(f(...)))
            end
        end
    )
end

skynet.start(dispatch)
