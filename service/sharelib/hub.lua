local skynet = require("skynet")
local utils = require("utils")

-- local events = {
--     [1]={
--         [1] = {fn=function() end}
--     },
--     [2]={
--         [1] = {fn=function() end}
--     },
--     [3]={
--         [1] = {fn=function() end}
--     },
-- }
-- utils.dump(events, "events")

local Hub = {
    events = {}
}

function Hub.register(mid, sid, fn)
    if fn == nil then
        return
    end

    local m = Hub.events[mid]
    if m == nil then
        m = {}
        Hub.events[mid] = m
    end

    local s = m[sid]
    if s == nil then
        s = {}
    end
    s.fn = fn
    m[sid] = s
end

function Hub.unregister(mid, sid)
    -- body
end

function Hub.dispatchMessage(mid, sid, data)
    local m = Hub.events[mid]
    if m == nil then return false end

    local s = m[sid]
    if s == nil then return false end

    assert(s.fn ~= nil)

    skynet.fork(s.fn, data)

    return true
end

return Hub