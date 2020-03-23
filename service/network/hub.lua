local skynet = require("skynet")

local Hub = {
    events = {}
}

function Hub.register(mid, sid, fn)
    if fn then
        local mids = Hub.events[mid]
        if mids == nil then
            mids = {}
            Hub.events[mid] = mids
        end

        local sids = mids[sid]
        if sids == nil then
            sids = {}
        end
        sids.fn = fn
        mids[sid] = sids
    end
end

function Hub.unregister(mid, sid)
    -- body
end

function Hub.dispatchMessage(mid, sid, data)
    local mmap = Hub.events[mid]
    assert(mmap ~= nil)

    local obj = mmap[sid]
    assert(obj ~= nil)

    assert(obj.fn ~= nil)
    
    skynet.fork(obj.fn, data)
end

return Hub