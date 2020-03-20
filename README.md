# skynet_gateway
skyent websocket网关服务

# 概要
    1. main.lua     程序入口
    2. ws_server    服务端
    3. ws_client    客户端
    
# 启动
    1. 单节点启动
        cd skynet_wsdemo
        bin/skynet conf/config
    2. 独立启动
        服务端启动:
            cd skynet_wsdemo
            bin/skynet conf/config_ws
        客户端启动
            cd skynet_wsdemo
            bin/skynet conf/config_client

# 代码结构
#### .
#### ├── common
#### │   ├── core.lua
#### │   ├── dump.lua
#### │   ├── export.lua
#### │   ├── function.lua
#### │   ├── trackback.lua
#### │   └── utils.lua
#### ├── config
#### │   └── config.lua
#### ├── main.lua
#### ├── network
#### │   ├── packet.lua
#### │   └── ws.lua
#### ├── proto_map
#### │   └── proto_map.lua
#### ├── testpk.lua
#### ├── ws_client
#### │   └── ws_client.lua
#### └── ws_server
####     ├── agent.lua
####     └── ws_server.lua
#### 