local pb = require("protobuf")
local skynet = require("skynet")

local pbfiles = {
    "service/protos/service.pb",
    "service/protos/lobby.pb"
}

proto_map = proto_map or {}

function proto_map.registerFiles(...)
    local args = {...}
    for i = 1, #args do
        pb.register_file(args[i])
        skynet.error("register protobuf [" .. args[i] .. "]")
    end
end

function proto_map.encode_ReqRegService(t)
    return pb.encode("Tws.ReqRegService", t)
end

function proto_map.decode_ReqRegService(data)
    return pb.decode("Tws.ReqRegService", data)
end

function proto_map.encode_AckRegService(t)
    return pb.encode("Tws.AckRegService", t)
end

function proto_map.decode_AckRegService(data)
    return pb.decode("Tws.AckRegService", data)
end

function proto_map.encode_ReqLogin(t)
    return pb.encode("lobby.ReqLogin", t)
end

function proto_map.decode_ReqLogin(data)
    return pb.decode("lobby.ReqLogin", data)
end

function proto_map.encode_AckLogin(t)
    return pb.encode("lobby.AckLogin", t)
end

function proto_map.decode_AckLogin(data)
    return pb.decode("lobby.AckLogin", data)
end


local function init()
    for i, c in pairs(pbfiles) do
        proto_map.registerFiles(c)
    end
end

init()
