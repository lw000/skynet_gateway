# skynet_gateway
skyent websocket网关服务

# 概要
    1. main.lua     程序入口
    
# 启动
    1. 单节点启动
        cd skynet_gateway
        bin/skynet conf/config

# 代码结构
#### .
#### ├── center_server
#### │   ├── agent_.lua
#### │   ├── center_server_.lua
#### │   ├── center_server.lua
#### │   ├── logic.lua
#### │   ├── manager.lua
#### │   └── route_map.lua
#### ├── common
#### │   ├── core.lua
#### │   ├── dump.lua
#### │   ├── export.lua
#### │   ├── function.lua
#### │   ├── trackback.lua
#### │   └── utils.lua
#### ├── config
#### │   └── config.lua
#### ├── core
#### │   └── define.lua
#### ├── db_server
#### │   ├── database
#### │   │   └── database.lua
#### │   ├── db_logic.lua
#### │   ├── db_manager.lua
#### │   └── db_server.lua
#### ├── gate_server
#### │   ├── agent.lua
#### │   ├── backend
#### │   │   └── backend.lua
#### │   └── gate_server.lua
#### ├── logon_server
#### │   ├── logon_logic.lua
#### │   ├── logon_manager.lua
#### │   └── logon_server.lua
#### ├── main_center.lua
#### ├── main_client.lua
#### ├── main_gate.lua
#### ├── main.lua
#### ├── network
#### │   ├── packet.lua
#### │   └── ws.lua
#### ├── proto_map
#### │   └── proto_map.lua
#### ├── redis_server
#### │   ├── redis_logic.lua
#### │   ├── redis_manager.lua
#### │   └── redis_server.lua
#### ├── skycommon
#### │   └── helper.lua
#### ├── testpk.lua
#### └── ws_client
####     └── ws_client.lua