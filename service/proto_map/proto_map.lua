require("service_config.type")
require("service_config.cmd")
require("proto_map.proto_func")

proto_map =
{
    [LOGON_CMD.MDM] = {
        [LOGON_CMD.SUB.REGIST] = {req=functor.reqRegist, ack=functor.ackRegist, desc="用户注册"},    
        [LOGON_CMD.SUB.LOGON] = {req=functor.reqLogin, ack=functor.ackLogin, desc="用户登录"},
        [LOGON_CMD.SUB.CHAT] = {req=functor.chatMessage, ack=functor.ackChatMessage, desc="聊天消息"}
    }
}

function proto_map.query(mid, sid)
    local object = proto_map[mid]
    if object == nil then
        return
    end
    local cmd = object[sid]
    if object == nil then
        return
    end
    return cmd
end

-- dump(proto_map, "proto_map")
