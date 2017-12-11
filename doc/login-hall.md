## client

在不引入gate的情况下，login可以对外暴露并绑定域名。client解析域名获取login列表，随机选择login或按三方登陆token hash login。

client配置hall地址列表是不对的，会面临难以更新的窘境。

## login/hall error

login/hall针对在线用户状态，互为备份。login可以定时ping hall。当发现hall上的数据丢失时，意味着hall发生了重启，此时对login记录的所有用户发起hall上的登陆操作。这个ping操作同样可用于login从hall恢复login自身的在线用户数据。

另一种容灾方式就是用redis，将状态数据同步到redis上，在重启后从redis恢复。
