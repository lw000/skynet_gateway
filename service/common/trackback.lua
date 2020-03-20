--引用通知，全局变量  跟踪绑定执行函数发生错误的信息并输
function __G__TRACKBACK__(msg)
    print("------------------------")
    print("LUA ERROR: " .. tostring(msg) .. "\n") -- 字符串连接（打印出消息）
    print(debug.traceback())
end