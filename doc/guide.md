## startup

```
./sh/redis.sh # start 1 redis instance
./sh/login.sh
./sh/hall.sh
./sh/game.sh
```

to run the test client:

```
./skynet/3rd/lua/lua test/i_client.lua
```

## hall与game

config.hall中新增配置

```
gameservers = 'game1;game2'
```

表示hall会与该配置中所有game进行交互，轮询其上的游戏列表，并负载均衡选择game创建房间。game名字对应skynet cluster map name。

## login与hall

config.login中配置hall列表：

```
hallservers='hall1;hall2'
```

## redis

reids instance 1用于存放通用数据。其他redis目前会根据uid hash，分别存放用户的数据。

