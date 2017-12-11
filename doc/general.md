# servers

* login server，包装skynet loginserver为独立进程
* hall server，大厅服务，负责大厅所有逻辑，负责分配玩家到具体游戏服务器
* game server，具体的游戏服务
* redis，充当全局配置管理，及缓存角色。有了全局配置管理，login/hall可以实现为无状态服务

## 连接关系

* hall 启动注册到redis，hall有唯一配置名字
* login 在处理登陆时负载均衡玩家到某个hall
* login 主要保存了uid到hall的映射，该数据缓存到redis，即使服务挂掉重启亦可恢复，且支持多instance
* hall 需要缓存管理的user列表，在挂掉恢复时重新载入该列表并登记到skynet msgserver，当玩家自主重登时可以正确处理
* login & hall 基于skynet loginserver/msgserver，以支持玩家断线重连
* game 启动时写入redis 游戏id及桌子列表
* hall 在接收玩家选择游戏桌号时找到对应的game server，准备移动玩家进游戏
* 玩家进入game后与hall断开连接，整个系统并不基于连接，玩家状态的清除由玩家显示登出驱动
* 每一局游戏有一个guid，玩家持久化该guid，游戏guid关联game server信息，重连时如果无法正确进入game则回到hall
* 如果需要考虑guid的非法截获，就需要将玩家登陆session信息与guid关联

## 框架与游戏

交互消息：

* 进入桌子，坐下

框架接口：

* 获取某座位玩家信息
* 向指定座位玩家发送消息
* 广播房间内消息
* 持久化玩家数据
* 定时器

## 缓存设计

## 持久化数据结构设计

## 断线重连

* 游戏过程中断线
* 大厅里断线

game上保存有所有玩家，client经过hall进入game前，hall会传递玩家当前的secret(联系msgserver的handshake)过去。game上用msgserver生成的username(目前是uid+server+subid)作为玩家标识。client连接game时，需要先如同连接hall时发送handshake。game以handshake作为合法性校验。

如果client与game断线，由于一般也会与hall断线，所以统一重连hall。hall需要持久化当前玩家所在的游戏及server信息。hall查询该信息通知client重连game。连接game无论重连还是首次连接处理相同，发送handshake。如果与hall并未断开连接，此时可以主动断开。如果client进程退出，重新开启后亦可以之前的handshake进入hall，相继进入game。





