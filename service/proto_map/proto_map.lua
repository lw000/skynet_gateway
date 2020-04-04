require("service_type")
require("service_cmd")
require("proto_func")
require("utils")

proto_map =
{
    [CENTER_CMD.MDM] = {
        desc = "中心服务",
        [CENTER_CMD.SUB.REGIST] = {unpack=functor.unpack_ReqRegService, pack=functor.pack_AckRegService, desc="注册服务"},
    },

    [LOBBY_CMD.MDM] = {
        desc = "大厅服务",
        [LOBBY_CMD.SUB.REGIST] = {unpack=functor.unpack_ReqRegist, pack=functor.pack_AckRegist, desc="用户注册"},
        [LOBBY_CMD.SUB.LOGON] = {unpack=functor.unpack_ReqLogin, pack=functor.pack_AckLogin, desc="用户登录"},
    },

    [CHAT_CMD.MDM] = {
        desc = "聊天服务",
        [CHAT_CMD.SUB.CHAT] = {unpack=functor.unpack_ChatMessage, pack=functor.pack_AckChatMessage, desc="聊天消息"}
    }
}

-- 查询指令封包解包接口
local function query(mid, sid)
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

-- 执行业务
function proto_map.exec(head, content, func)
    -- 解包接口
    local cmd = query(head.mid, head.sid)
    if cmd == nil then
        local errmsg = "unknown proto_map [mid=" .. tostring(head.mid) .. " sid=" .. tostring(head.sid) .. "] command"
        return 1, errmsg
    end

    if cmd.unpack == nil then
        local errmsg = "proto_map [PB]协议解包接口不存在"
        return 2, errmsg 
    end
    
    if cmd.pack == nil then
        local errmsg = "proto_map [PB]协议封包接口不存在"
        return 3, errmsg 
    end

    -- 1. [PB]协议·解包
    local reqContent = cmd.unpack(content.data)
    -- 2. 业务处理
    local ackContent = func(head, reqContent)
    if ackContent == nil then
        local errmsg = "接口无返回值"
        return 4, ""
    end
    -- 3. [PB]协议·封包
    return 0, cmd.pack(ackContent)
end
