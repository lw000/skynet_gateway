local skynet = require("skynet")

local _open = true

local timer = {
    
}

local function check(second, func)
    assert(second ~= nil, "second must is number")
    assert(type(second) == "number", "second must is number")
    assert(func ~= nil)
    assert(type(func) == "function", "func must is function")

    if second < 0 then
        second = 0
    end

    return second, func
end

function timer.runEvery(second, func)
    second, func = check(second,func)

    local function loop()
        if _open then
            skynet.timeout(100*second, loop)
            skynet.fork(func)
        end
    end

    skynet.timeout(100*second, loop)
end

function timer.runAfter(second, func)
    second, func = check(second,func)
    local function loop()
        if _open then
            skynet.fork(func)
        end
    end
    skynet.timeout(100*second, loop)
end

function timer.stop()
    _open = false
end

return timer