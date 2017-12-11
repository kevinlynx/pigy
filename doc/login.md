## 登陆

login实现了3个接口：

* register，用于添加账号
* login，登陆验证
* bind，绑定游客账号

对应到3种账号体系：

* 第三方平台认证，直接尝试登陆，失败则以三方平台token自动注册
* 自有账号体系，客户端引导用户注册
* 游客账号，直接尝试登陆，失败则以机器标识注册。
* 可以绑定三方平台token到游客账号

账号数据库至少包含信息：

* uid
* pid, 三方平台token; 注册账号; 机器标识
* sdkid, 账号类型：1: 自有账号；2: 游客；; 10+: 三方平台
* password, 除了自有账号外都为空


客户端登陆验证：

```
h = desencode(username, password) ||
    desencode(3rd_sdk_token, '') ||
    desencode(machine_id, '')
```

