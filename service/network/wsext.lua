local skynet = require("skynet")
local packet = require("network.packet")
require("common.export")

local WSClient = class("WSClient")

function WSClient:ctor()
    self._wsid = -1
    self._websocket = nil
    self._scheme = ""
    self._host = ""
    self._path = ""
    self._timeout = 100 * 15 -- 网络连接超时时间
    self._on_message = nil
    self._on_error = nil
    self._open = false
    self._debug = false
    self:reset()
end

function WSClient:connect(scheme, host, path)
    assert(scheme ~= nil and type(scheme) == "string", "scheme must is string")
    assert(host ~= nil and type(host) == "string", "host must is string")

    path = path or ""
    assert(type(path) == "string", "path must is string")

    self._scheme = scheme
    self._host = host
    self._path = path

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

function WSClient:send(content)
    assert(content ~= nil, "content can't nil")
    self._websocket.write(self._wsid, content, "binary", 0x02)
end

function WSClient:open()
    return self._open
end

function WSClient:reset()
    self._open = false
    self._wsid = -1
end

function WSClient:handleMessage(fn)
    self._on_message = fn or function(data) end
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
        
        if self._on_message then
            skynet.fork(self._on_message, resp)
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
