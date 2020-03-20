local pb = require("protobuf")
local packet = require("network.packet")

pb.register_file("./protos/service.pb")
print("注册[service.pb]协议")

function packTest()
    local content =
        pb.encode(
        "Tapi.ReqRegService",
        {
            serverId = 0,
            svrType = 5
        }
    )

    local pk = packet:new()
    pk:pack(0x0001, 0x0001, 1, content)
    print("pk", pk:ver(), pk:mid(), pk:sid(), pk:checkCode(), pk:clientId())
    local pk1 = packet:new()
    pk1:unpack(pk:data())
    print("pk1", pk1:ver(), pk1:mid(), pk1:sid(), pk1:checkCode(), pk1:clientId())

    local data1 = pb.decode("Tapi.ReqRegService", pk1:data())
    print("数据解码：serverId=" .. data1.serverId .. ", svrType=" .. data1.svrType)

    -- local ver = 0
    -- local mid = 0x0001
    -- local sid = 0x0001
    -- local checkCode = 0
    -- local clientId = 500000

    -- local data = string.pack("<I2", ver)
    -- data = data .. string.pack("<I4", mid)
    -- data = data .. string.pack("<I4", sid)
    -- data = data .. string.pack("<I8", checkCode)
    -- data = data .. string.pack("<I8", clientId)
    -- if content then
    --     data = data .. content
    -- end

    -- local ver_1 = string.unpack("<I2", data)
    -- print(ver_1)
    -- data = data:sub(3)
    -- local mid_1 = string.unpack("<I4", data)
    -- print(mid_1)
    -- data = data:sub(5)
    -- local sid_1 = string.unpack("<I4", data)
    -- print(sid_1)
    -- data = data:sub(5)
    -- local checkCode_1 = string.unpack("<I8", data)
    -- print(checkCode_1)
    -- data = data:sub(9)
    -- local clientId_1 = string.unpack("<I8", data)
    -- print(clientId_1)
    -- data = data:sub(9)
    -- local data1 = pb.decode("Tapi.ReqRegService", data)
    -- print("数据解码：serverId=" .. data1.serverId .. ", svrType=" .. data1.svrType)
end