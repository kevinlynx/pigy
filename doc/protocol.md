# 说明

目前client与server的协议已经基于数字，通过一个中间层来映射数字到rpc。参考`messageid.lua`及`protocol/*.proto`

# 具体协议

主要列举与客户端的协议

## 进入hall

* C2H, handshake
* C2H, get user
* if user.has_room then 
    * C2H, reconn room
    * C2G, 参考进入Game
* C2H, get room&game list

## 选择房间

* C2H, select room
* C2G, 参考进入Game

## 创建房间

* C2H, create room
* C2G, 参考进入Game

## 离开房间

* C2H, leave room

## 销毁房间

* C2H, destroy room

## 进入Game

* C2G, handshake
* C2G, enter game

## 重连

* 进程退出, 完整登陆流程
* 大厅内断线，基于msgserver handshake hall重连。hall重发缓存消息
* 游戏内断线
    * 全量重连：正常进入游戏逻辑，获取游戏全量状态
    * 增量重连：需要game支持断线重连协议，补发部分消息



