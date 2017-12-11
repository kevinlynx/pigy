
## 功能设计

需要持久化数据：

* room
* user
* account

数据持久化在目前的memory+redis+mysql三层结构中，mysql持久化基本上只是数据的备份，在服务器挂掉重启后载入恢复使用。

### Room

room表仅存储当前使用中的房间。已结束的房间可存储到历史表中。hall启动时载入所有room到redis，并去game上ensure该room存在。room需要有扩展状态，根据不同游戏状态内容不一样。

## 框架相关

* Entity (recordset, table)
    * UserEntity / UserSingleEntity / d_user
    * CommEntity / d_account
* datacenter (service)
    * accountdc
    * userdc
* dbmgr (load from redis first)

```
recordset[k] = v
k = ','.join(map(lambda k: row[key], config.key.split(',')))
相当于取一行记录中的关键值作为key
```

```
UserSingleEntity:load(uid)
    call dbmgr to load a user by uid, store it in self.recordset
```

* config
    * columns (db table columns)
    * name (db table name)
    * key (for redis)
    * indexkey (for redis)

```
uid用作redis分partition

insert row:
    rediskey = tbname..row[key]
    hmset(rediskey, row): HMSET rediskey k1 v1 k2 v2 # 一行记录对应redis一个哈希表
    zadd(tbname..':index:'..row[indexkey], rediskey) # 对所有rediskey做索引
```

以上，由于表的每一行都作为redis中的一个独立hashmap，当尝试载入整张表数据时，由于并不知道整张表有多少数据，所以`zadd`添加的有序集合，实际就表示了该表里所有行记录的key，基于该key可以进一步从redis中查出完整的db行数据。

表类型：

* config，应该是一些特别轻量的表，类似配置，数据很少
* common，相对数据更多，但也可以全量载入redis，例如账号
* user，不能全量载入，在使用时根据uid载入，其中根据uid是否重复分为单行和多行

dbsync 服务其实只是一个sql语句缓存执行队列，可以让sql操作异步化。

整体上结构是3级缓存：本地内存、redis、mysql

