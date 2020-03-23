local skynet = require("skynet")

local _open = true

local timer = {
    
}

function timer.start(second, func)
    assert(second ~= nil, "second must is number")
    assert(type(second) == "number", "second must is number")
    
    if second < 0 then
        second = 0
    end

    local function loop()
        if _open then
            skynet.timeout(100*second, loop)
            skynet.fork(func)
        end
    end

    skynet.timeout(100*second, loop)
end

function timer.stop()
    _open = false
end

return timer