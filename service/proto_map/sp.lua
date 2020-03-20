local pb = require("protobuf")

local pb_files = {
    "service/protos/service.pb",
    "service/protos/lobby.pb",
    "service/protos/chat.pb"
}

functor = functor or {}

function functor.encode_ReqRegService(t)
    return pb.encode("Tws.ReqRegService", t)
end

function functor.decode_ReqRegService(data)
    return pb.decode("Tws.ReqRegService", data)
end

function functor.encode_AckRegService(t)
    return pb.encode("Tws.AckRegService", t)
end

function functor.decode_AckRegService(data)
    return pb.decode("Tws.AckRegService", data)
end

-- 编码·登录请求
function functor.encode_ReqLogin(t)
    return pb.encode("lobby.ReqLogin", t)
end

-- 解码·登录请求
function functor.decode_ReqLogin(data)
    return pb.decode("lobby.ReqLogin", data)
end

-- 编码·登录回应
function functor.encode_AckLogin(t)
    return pb.encode("lobby.AckLogin", t)
end

-- 解码·登录回应
function functor.decode_AckLogin(data)
    return pb.decode("lobby.AckLogin", data)
end

-- 编码·聊天请求消息
function functor.encode_ChatMessage(t)
    return pb.encode("chat.ChatMessage", t)
end

-- 解码·聊天请求消息
function functor.decode_ChatMessage(data)
    return pb.decode("chat.ChatMessage", data)
end

-- 编码·聊天回应消息
function functor.encode_AckChatMessage(t)
    return pb.encode("chat.AckChatMessage", t)
end

-- 解码·聊天回应消息
function functor.decode_AckChatMessage(data)
    return pb.decode("chat.AckChatMessage", data)
end

local function registerFiles(...)
    local args = {...}
    for i = 1, #args do
        pb.register_file(args[i])
        print("register protobuf [" .. args[i] .. "]")
    end
end

local function init()
    for i, f in pairs(pb_files) do
        registerFiles(f)
    end
end

init()