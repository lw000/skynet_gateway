require("service_config.type")
require("service_config.cmd")
require("proto_map.proto_func")

proto_map = proto_map or {
    [LOGON_CMD.MDM_LOGON] = {
        [LOGON_CMD.SUB.LOGON] = {req=functor.decode_ReqLogin, ack=functor.encode_AckLogin, desc="用户登录"},
        [LOGON_CMD.SUB.CHAT] = {req=functor.decode_ChatMessage, ack=functor.encode_AckChatMessage, desc="聊天消息"}
    }
}

-- dump(proto_map, "proto_map")
