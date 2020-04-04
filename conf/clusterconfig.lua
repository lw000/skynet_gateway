-- If you turn this flag off, cluster.call would block when node name is absent
__nowwaiting = true

-- 中心服务器集群配置
master = "127.0.0.1:9100"
-- 大厅服务器集群配置
lobby = "127.0.0.1:9101"
-- 日志服务器集群配置
log  = "127.0.0.1:9102"
-- 游戏服务器集群配置
game = "127.0.0.1:9103"
-- 聊天服务器集群配置
chat = "127.0.0.1:9104"
-- DB服务器集群配置
db  = "127.0.0.1:9106"