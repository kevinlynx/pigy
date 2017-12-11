* logout
* ~~login/hall互为备份recover用户登录状态~~
* ~~client是否只需要配置一个login地址，不需要hall地址；支持多login/hall~~
* 梳理所有服务重入的地方，可能由于服务重入引入bug
* ~~load balancing to select a game server to create room~~
* ~~load balancing to select a hall server~~
* ~~destroy room~~
* ~~leave room~~
* game server ping
* ~~进入hall后获取用户数据，包括可能已经进入的房间信息。如果有房间信息则重新进入~~
* ~~data persist~~
* game framework
* 全服广播通知
* benchmark
* ~~重新进入game server房间~~
* 断线重连问题
    * msgserver本身带了基于session的缓存，client进程退出后，应该重走登陆流程，而不是直接与hall重连，因此此时session号重置会导致收到很多缓存回应；client因为网络不稳定时才直接与hall重连，此时可以理解为hall将之前可能丢失的消息重发给client，但这也是基于session，这还要求client能记录哪些session需要重新请求
    * gameserver 重连问题，是否也需要基于断线重连协议
* ~~select room~~
* ~~目前对游戏的定义是有问题的，玩家进入game应该是创建了房间，房间内可以开启若干次具体游戏~~
* ~~game server 中使用fd去代表玩家，关联游戏是有问题的，无法处理断线重连的问题~~
* ~~目前的网络协议依靠字符串来自动route到rpc服务，有点浪费网络带宽~~
* 交互式客户端，测试全流程
    * ~~persist login state and relogin~~
* 各个server挂掉后的异常测试
    * login重启后由于hall有登陆记录导致无法登陆
    * hall挂掉后: a) client自动重连失败；b) client重启登陆正常
* server状态梳理，确认是否无状态
    * login主要是logind中的online user
    * hall主要是msgserver中的online user及msgagent
* reconnect to game server
* 异常流程测试
    * 玩家重复登录

