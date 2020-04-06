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
#### │   ├── agent.lua
#### │   ├── center_logic.lua
#### │   ├── center_route.lua
#### │   └── center_server.lua
#### ├── chat_server
#### │   ├── chat_server.lua
#### │   └── service
#### │       ├── chat_logic_func.lua
#### │       └── chat_logic_server.lua
#### ├── common
#### │   ├── function.lua
#### │   ├── trackback.lua
#### │   └── utils.lua
#### ├── config
#### │   └── config.lua
#### ├── db_server
#### │   ├── database
#### │   │   └── database.lua
#### │   ├── db_server.lua
#### │   └── service
#### │       └── db_logic_server.lua
#### ├── gate_server
#### │   ├── agent.lua
#### │   ├── gate_server.lua
#### │   ├── global.lua
#### │   └── proxy
#### │       ├── center_proxy.lua
#### │       └── master_proxy.lua
#### ├── lobby_server
#### │   ├── lobby_logic.lua
#### │   └── lobby_server.lua
#### ├── main_center.lua
#### ├── main_gate.lua
#### ├── main.lua
#### ├── main_master.lua
#### ├── main_robot.lua
#### ├── master_server
#### │   ├── master_service.lua
#### │   └── proxy
#### │       └── master_proxy.lua
#### ├── network
#### │   ├── packet.lua
#### │   ├── wsext.lua
#### │   └── ws.lua
#### ├── proto_map
#### │   ├── proto_func.lua
#### │   └── proto_map.lua
#### ├── protos
#### │   ├── build.sh
#### │   ├── chat.pb
#### │   ├── chat.proto
#### │   ├── lobby.pb
#### │   ├── lobby.proto
#### │   ├── service.pb
#### │   └── service.proto
#### ├── redis_server
#### │   ├── logic.lua
#### │   ├── manager.lua
#### │   └── redis_server.lua
#### ├── robot_server
#### │   └── robot_server.lua
#### ├── service_config
#### │   ├── service_cmd.lua
#### │   └── service_type.lua
#### ├── sharelib
#### │   ├── hub.lua
#### │   ├── logger.lua
#### │   └── timer.lua
#### ├── skycommon
#### │   └── helper.lua
#### └── testpk.lua