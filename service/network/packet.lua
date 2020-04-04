require("export")
local Packet = class("Packet")

function Packet:ctor()
    self._ver = 0
    self._mid = 0
    self._sid = 0
    self._checkCode = 0
    self._clientId = 0
    self._data = nil
end

function Packet:pack(mid, sid, clientId, content)
    self._mid = mid
    self._sid = sid
    self._clientId = clientId
    local data = string.pack("<I1", self._ver)
    data = data .. string.pack("<I4", self._checkCode)
    data = data .. string.pack("<I2", mid)
    data = data .. string.pack("<I2", sid)
    data = data .. string.pack("<I4", self._clientId)
    if content then
        data = data .. content
    end
    self._data = data
end

function Packet:unpack(data)
    self._ver = string.unpack("<I1", data)

    data = data:sub(2)
    self._checkCode = string.unpack("<I4", data)

    data = data:sub(5)
    self._mid = string.unpack("<I2", data)

    data = data:sub(3)
    self._sid = string.unpack("<I2", data)

    data = data:sub(3)
    self._clientId = string.unpack("<I4", data)
    
    data = data:sub(5)
    self._data = data
end

function Packet:ver()
    return self._ver
end

function Packet:mid()
    return self._mid
end

function Packet:sid()
    return self._sid
end

function Packet:checkCode()
    return self._checkCode
end

function Packet:clientId()
    return self._clientId
end

function Packet:data()
    return self._data
end


return Packet