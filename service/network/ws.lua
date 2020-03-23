local skynet = require("skynet")
local packet = require("network.packet")

local WSClient = class("WSClient")

function WSClient:ctor()
    self._wsid = -1
    self._websocket = nil
    self._scheme = ""
    self._host = ""
    self._path = ""
    self._heartbeattime = 30 -- 心跳时间
    self._timeout = 100 * 15 -- 网络连接超时时间
    self._msgswitch = {}
    self._on_message = nil
    self._on_error = nil
    self._open = false
    self._debug = false
    self:reset()
end

function WSClient:connect(scheme, host, path, heartbeattime)
    assert(scheme ~= nil and type(scheme) == "string", "scheme must is string")
    assert(host ~= nil and type(host) == "string", "host must is string")

    path = path or ""
    assert(type(path) == "string", "path must is string")
    
    heartbeattime = heartbeattime or 30
    assert(type(heartbeattime) == "number", "heartbeattime must is number")

    self._scheme = scheme
    self._host = host
    self._path = path
    self._heartbeattime = heartbeattime

    local url = string.format("%s://%s/%s", self._scheme, self._host, self._path)
    skynet.error("ws connect to", url)

    local do_connect = function()
        self._websocket = require "http.websocket"
        self._wsid = self._websocket.connect(url, nil, self._timeout)
    end

    local on_error = function(err)
        self._on_error(err)
    end

    local ok = xpcall(do_connect, on_error)
    if not ok then
        return 1, "ws connect fail"
    end

    skynet.error("ws connect success wsid=" .. self._wsid)

    self._open = true

    --心跳处理
    local function on_heartbeat()
        if self._open then
            skynet.timeout(100*self._heartbeattime, on_heartbeat)
        end
        self:send(0x0000,0x0000,nil,function(pk)
            skynet.error("heartbeat", os.date("%Y-%m-%d %H:%M:%S", os.time()))
        end)
    end
    skynet.timeout(100*self._heartbeattime, on_heartbeat)

    -- 读取数据
    skynet.fork(function()
        -- debug.traceback
        local ok = xpcall(function() self:loopRead() end, function(err) self._on_error(err) end)
        -- dump(ok, "run")
        skynet.error("websocket loopRead exit")
        self:reset()
    end)

    return 0
end

function WSClient:send(mid, sid, content, fn)
    return self:sendWithClientId(mid, sid, self._wsid, content, fn)
end

function WSClient:sendWithClientId(mid, sid, clientId, content, fn)
    if not self._open then
        skynet.error("websocket is closed")
        return 1
    end

    if fn then
        local mids = self._msgswitch[mid]
        if mids == nil then
            mids = {}
            self._msgswitch[mid] = mids
        end

        local sids = mids[sid]
        if sids == nil then
            sids = {}
        end
        sids.fn = fn
        mids[sid] = sids
    end

    local pk = packet:new()
    pk:pack(mid, sid, clientId, content)
    if pk:data() == nil then
        skynet.error("data is nil")
        return 1
    end
    self._websocket.write(self._wsid, pk:data(), "binary", 0x02)
    return 0
end

function WSClient:open()
    return self._open
end

function WSClient:reset()
    self._open = false
    self._wsid = -1
end

function WSClient:handleMessage(fn)
    self._on_message = fn or function(pk)
        skynet.error("mid=" .. pk:mid(), "sid=" .. pk:sid(), "clientId=" .. pk:clientId(), "默认·消息·函数")
    end
end

function WSClient:handleError(fn)
    self._on_error = fn or function(err)
        skynet.error(err)
    end
end

function WSClient:loopRead()
    while self._open do
        local resp, close_reason = self._websocket.read(self._wsid)
        if not resp then
            skynet.error("<:", (resp and resp or "[Close] " .. close_reason))
            skynet.error("server close")
            break
        end

        local pk = packet:new()
        pk:unpack(resp)

        local mid = pk:mid()
        local sid = pk:sid()
        local ver = pk:ver()
        local checkCode = pk:checkCode()
        local clientId = pk:clientId()

        if self._debug then
            skynet.error("<: wsclient","ver=" .. ver,"mid=" .. mid,"sid=" .. sid,"checkCode=" .. checkCode,"clientId=" .. clientId,"dataLen=" .. string.len(pk:data()))
        end

        local mids = self._msgswitch[mid]
        if mids then
            local sids = mids[sid]
            if sids and sids.fn then
                skynet.fork(sids.fn, pk)
            else
                if self._on_message then
                    skynet.fork(self._on_message, pk)
                end
            end
        else
            if self._on_message then
                skynet.fork(self._on_message, pk)
            end
        end
    end
end

function WSClient:dubug(debug)
    assert(debug ~= nil and type(debug) == "boolean", "debug value must is boolean")
    self._debug = debug
end

function WSClient:close()
    self._websocket.close(self._wsid)
    self:reset()
end

return WSClient
