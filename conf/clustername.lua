-- If you turn this flag off, cluster.call would block when node name is absent
__nowwaiting = true

-- 中心服务器集群配置
master = "127.0.0.1:10003"
-- 大厅服务器集群配置
hall = "127.0.0.1:9001"
-- 日志服务器集群配置
log  = "127.0.0.1:9000"
game = "127.0.0.1:9501"