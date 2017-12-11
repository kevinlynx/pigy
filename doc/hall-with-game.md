# Hall与Game的交互

## 定义

* 房间；单个game可以静态或动态配置房间列表。房间有属性，如：人数、关联的游戏类型、金额统计等。房间可以由GM或玩家创建。房间需要持久化
* 游戏：依附于房间内

## 游戏列表获取

Game需配置自己支持的游戏列表。Game在启动时会载入所有自己关联的房间列表，如果某房间关联游戏不在该Game内，该房间本次载入失败。游戏列表配置：

```
[
    {name: 'chat', id: 101}
]
```

Hall向Game请求所有房间列表，并以游戏id聚合，client就可以按游戏展现房间列表。

```
[
  {
    'GameID': 101,
    'Rooms': [
      {
        'ID': 1,
        'State': 0,
        'PlayerCount': 3,
        'Extra': ''
      }
    ]
  }
]
```

`Extra` 扩展信息一般是客户端与Game的协商结果。Hall端在一轮询问结束后更新本地的游戏状态，该状态也会同步到客户端。

## 进入房间

流程：

* 玩家选择游戏，Client展示房间列表
* 玩家创建房间或选择房间进入

系统：

* Client -> Hall: 创建房间并进入；选择房间进入
* [创建时] Hall -> Game: 创建房间，返回房间id
* Hall -> Game: 玩家登记，关联Room与玩家
* Client -> Game: handshake，Game验证Client
* Client -> Game: 进入房间

## 断线重连

进程未结束，网络异常：

* Client -> Hall: handshake，基于msgserver重连进入
* Hall: 检查玩家是否有关联的房间，有则进入
* Client -> Game: handshake
* Client -> Game: 进入房间

进程结束：

* 走完整登陆流程

## 房间生命周期

* room id以数据库主键为准，全局唯一
* hall通知game创建
* 用户选择房间进入，并关联房间id持久化
* owner client可以发消息结束房间
* game有接口由游戏逻辑决定结束房间
* room结束需广播消息给所有用户
* room结束后需从持久化数据中移除，可放置到历史room表中
* user离开room需要更新user关联的room
