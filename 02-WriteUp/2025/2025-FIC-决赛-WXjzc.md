---
title: "2025 FIC 决赛 WP（WXjzc）"
type: writeup
category: ""
competition: "FIC"
year: "2025"
stage: "决赛"
mode: ""
tags: [FIC, 手机取证, 磁盘取证, 服务器取证, 数据库取证, 加解密, Docker, APK分析]
images: 110
status: "参考"
source: "参考WP"
created: 0000-00-00
updated: 2026-09-01
summary: "《2025 FIC决赛》题解：手机/加密系统与Kali磁盘、服务器与Docker容器、路由器、APP五类检材，含RAID重组与SO加密分析（参考WP）"
---
# 2025 FIC 决赛 WP（WXjzc）

容器密码：F!C_2025-Final@决~赛#x7Pz!
加密系统
密码为"2025=(20+25)^2"，大部分钱财相关内容都保留在了加密系统上。

# 手机取证

## 1.请分析检材1，该检材的蓝牙mac地址为

![](fd67d300b12001aba88cc6e0ac89963c.webp)

结果为`a4:55:90:15:2e:76`

## 2.请分析检材1，该检材的系统Linux内核版本号为

![](8ec7f7810ff169da4ff416c94b5686aa.webp)

结果为`4.14.186`

## 3.请分析检材1，该检材中实际使用的密码管理软件的软件包包名为

keepass数据库里没有数据，还有其他包，不过都不是

![](460dbd62bf2ee299f22d7a06e895d9a7.webp)

![](edc905421f9d0adc2281287acfd2ed4d.webp)

结果为`design.codeux.authpass.fdroid`

## 4.请分析检材1，该检材中密码管理软件的主密钥为

![](a0e3e096d17cd8487b20501746c2c207.webp)

结果为`Save my P Ass.`

## 5.请分析检材1，该检材中保存的github.com密码为

keepass打开

![](3e1f65c360131e86635fe185b4123e8d.webp)

结果为`Forensix777`

## 6.请分析检材1，该检材root工具的版本为

magisk，看packages.list

![](0f02197986bb1e94bf0a1ccdca9199ec.webp)

这个对应的版本名是v27.0，可以下载对应的包查看

结果为`27.0`

## 7.请分析检材1，找到该手机上的Linux容器，并回答下列问题，该Linux发行版名称为

包名有linux关键词

![](760b1947772490c6d1360a60b2d4be45.webp)

结果为`debian`

## 8.请分析检材1容器，该系统默认桌面环境为

![](004c1402d1fb72c81c56067931db4e9e.webp)

结果为`xfce`

## 9.请分析检材1容器，该系统的android用户密码为

见7图

结果为`99c26da5`

## 10.请分析检材1容器，浏览器下载的文件名为

linux的镜像

![](9dc715eda893f70f83c0be0ee0a510bd.webp)

加载镜像继续分析

![](691382b7a69e928a8a5e79d23594d564.webp)

结果为`reshacker_setup.exe`

## 11.请分析检材1容器，陈某使用过的github代理的域名为

![](975c4309367e2c8c90f067834c962f1d.webp)

结果为`gh.viru.sh`

## 12.请分析检材1容器中助记词程序recphrase，其使用的壳类型为

![](ddee4b1ba655840f7354a59da0682958.webp)

查一下是upx

![](9d06eb122b62163a93c41140723d250c.webp)

结果为`upx`

## 13.请分析上题程序，程序运行后第2列第3行助记词为

`upx -d`脱壳，重新检测，发现是pyinstaller打包

![](264b35cdfe30f1d74e8e2a47bb75968b.webp)

反编译reco.pyc即可

![](ff007812afb8d8643e93b85830db0d07.webp)

代码拿下来跑一下即可

![](6ce8d739c6fcadec3640bbb91dd844db.webp)

结果为`village`

## 14.请分析上题程序，该组助记词对应的钱包种子前8位为

![](6c67230447aacdcc8a5c7c2127868010.webp)

结果为`e08478b0`

## 15.请分析检材1容器，钓鱼网站（phishing）的后台用户密码加密算法为

历史命令可以找到网站

![](2af2d7aa4835fd273492127365b2b5b5.webp)

用的是django的默认算法

![](3371558ef8d6b518ae19b55aaf022880.webp)

查看数据库可以知道

![](6114fbbc4814ea2b92f84a31e40822ed.webp)

结果为`pbkdf2_sha256`

## 16.请分析检材1容器，钓鱼网站超管用户的弱口令为

启动后，123456直接登录成功了。。。理想情况下可以用bp这些发包

![](2e66c6f50defb1db0b612083472203a8.webp)

结果为`123456`

## 17.请分析检材1容器，宝塔面板的入口为

![](43fab249460ae26cc240bb11f26de2e0.webp)

结果为`/a2d3e161`

## 18.请分析检材1容器，宝塔面板运行在aarch64内核时报错的so文件为

![](2c92a1a85b89663317ba48aaf3ba73ba.webp)

结果为`PluginLoader.so`

# 计算机取证

## 1.请分析检材2，该检材系统中设备名称为neo4chen的系统分区的sha256值为

![](b775fdfc5c8f503c2a446bacd8311a8b.webp)

结果为`E2219548F5A8E61F373258EB658625ADDA7BF858A83AD8D6E4213BCD8ECEB423`

## 2.请分析检材2，上题系统中，曾被远程控制的ip为

`\Windows\System32\winevt\Logs\Microsoft-Windows-TerminalServices-RemoteConnectionManager%4Operational.evtx`

![](d47e53a8c52f8c387db7c9c079a967b2.webp)

结果为`192.168.3.14`

## 3.请分析检材2加密系统，陈某通过物理方式保存助记词的东西名为

便签里有东西，按照这个规则，应该是`2025=(20+25)^2`，仿真时使用这个密码可以成功启动系统

![](76d0d45740ed940aff665592f38d3c96.webp)

![](cd0e52b115180348335ea26dc5ef531d.webp)

进入后，卷3是加密系统，卷6是不加密的，密码之前手机的keepass里有，是`chenhaobei`

开机后非常抽象

![](da98a0db7867386568febd73f1a7c089.webp)

远程桌面过去最好，vmware操作会很卡，打开显示设置，把缩放改回100

![](96408bec0f93b238cda60f0ec823a8f7.webp)

![](a614d513e1ee3c0a810b21253eba69a2.webp)

结果为`时光密钥`

## 4.请分析检材2加密系统，陈某保存记录完整助记词的文件的md5值为

这个图片尾部还有数据

![](785ad256825bfedfd34ec00662bf7065.webp)

导出来是完整的

![](f56e31e04ede01d429bfc09255446b2b.webp)

![](399f51752570095ec89566d581620067.webp)

结果为`C2A8300C87F86BD04B4AEA42E7D6B83C`

## 5.请分析检材2加密系统，陈某交代XI位为2^1，上题文件对应中文助记词不包含一下哪一项

转为二进制，然后根据图片上的xor 1988异或出顺序，再按照标准bip39简中的字典查字

```python
lst = []
lst.append(int("11100111101",2))
lst.append(int("11000000001",2))
lst.append(int("11111010110",2))
lst.append(int("01101010000",2))
lst.append(int("11000110110",2))
lst.append(int("00000000101",2))
lst.append(int("10001001000",2))
lst.append(int("11001111010",2))
lst.append(int("00001111000",2))
lst.append(int("00001100001",2))
lst.append(int("00000011001",2))
lst.append(int("10001011011",2))
with open("bip39_chinese_simplified.txt",'r',encoding='utf-8') as f:
    lines = f.readlines()
    for v in lst:
        print(lines[(v^1988)-1].strip(),end="")
```

![](f8c92b4d9746cce6f9a2f14655580541.webp)

## 6.请分析检材2加密系统，该检材加密系统中陈某自白的录音最后修改时间为

![](d236c0b95cfbf36383c69311129d65fd.webp)

结果为`2025-05-14 20:59:20`

## 7.请分析检材2加密系统，陈某和李某共同出行的户外活动为

录音转文字

![](c8ef1d36d85d542a77e038aa2f5eecb2.webp)

结果为`钓鱼`

## 8.请分析检材2加密系统，陈某自白中的隐藏的“学习资料”所在服务器ip地址为

音频分离出伴奏（我用的NovaMSS），看频谱读摩斯，按照摩斯的间隔给点

![](5f3328aacaeb5cf5cb217071007bd5d9.webp)

结果为`114.51.41.91`

## 9.请分析检材2加密系统，存放欠条的加密容器文件名为

![](957b1eaaa715b061d478008278238765.webp)

结果为`我的手机号`

## 10.请分析检材2加密系统，该容器欠条中赵某欠陈某多少虚拟币

初赛中的两个手机号，一个解正常分区`3170010703`，一个解隐藏分区`13170010703`

![](f2e1000ce5249ad409c9a8799dadc298.webp)

结果为`0.079BTC`

## 11.请分析检材2加密系统，该检材中ubuntu光盘文件的系统内核版本号为

![](45b0ebfdbdc894e2c10acdef5663a9bb.webp)

结果为`4.15.0`

## \*12.请分析检材2Linux系统，该系统的当前状态为

![](d790995c1388b12fe90b83f1f2ad031f.webp)

不确定

结果为`hibernate`

## 13.请分析检材2Linux系统，该系统使用了什么阵列

![](fc9a3b90876368ffe40439cf15a41ce2.webp)

结果为`raid0`

## 14.请分析检材2Linux系统，系统自带记事本软件中记录的密码的未知位数有几位

![](e9f242122bc31a3a5217ee4452655489.webp)

结果为`4`

## 15.请分析检材2Linux系统，系统自带记事本内容缓存在重组后逻辑分区中的起始偏移地址为

![](4a7307318d4405b2c620aac4bdbc9629.webp)

结果为`296d90000`

## 16.请分析检材2Linux系统，chrome浏览器插件的保护密码为

仿真pc镜像， 打开电源时进入固件，从文件引导，选第一个分区，最后找到`efi/kali/grubx64.efi`成功引导，账号密码和win一样

![](1599f267ff7f75f59318e44a25beaec3.webp)

![](fc0fea1006ce696ec39cac81ef3f0836.webp)

![](e9deaed8d1936524326419547f819352.webp)

浏览器里调试一下，可以找到主要逻辑

![](7b5e24866dccb7a6fec3642f05381887.webp)

![](bec4bcf04652b7c490fb2e53e3b74fe1.webp)

写代码掩码攻击，但是我这里不知道为什么node的环境没法验证，只能用python的环境验证，很麻烦。。。

```javascript
const CryptoJS = require("crypto-js");
const fs = require("fs");
var data = "";
for(var i=0;i<10000;i++){
  var password = "chewhaoN@"+String(i).padStart(4, '0');
  // 调试拿到密文
  var key1 = CryptoJS.AES.decrypt("U2FsdGVkX18Tb9IA8UF4TbpMQjOs4IqZBTIkldDlgn9vw1gIF9ltOirI/lf1SCGh9hAskbnb7cIsoJL6mNii7pQ1SDSt9R7vzF3Y+/d/fPtKXHMisjbQK/U6t+3wREAuoKQ4yZ24iuw+KZ6CW9bl6ULp3nVx0B8QpueW95sw0KOtmOMpmD19nO6gkFvMohcB", password).toString();
  data += password + " "+key1 + "\n";
}
const options = { encoding: 'utf8', mode: 0o666, flag: 'w' };

fs.writeFile('output.txt', data, options, (err) => {
  if (err) {
    console.error('Error writing file:', err);
  } else {
    console.log('File written successfully');
  }
});
```

```python
import argon2

argon2_hasher = argon2.PasswordHasher()
argon2_hash = argon2_hasher.hash(password="password")
# 调试拿到哈希
hash = "$argon2id$v=19$m=16384,t=1,p=1$k6EZEDdQYyn+/0GlJtZGpg$hicAuwJorE73Moj+Po2Txda8hyoPPGYa"
with open("output.txt","r",encoding="utf-8") as file:
    lines = file.readlines()
    for line in lines:
        line = line.strip()
        m = line.split(" ")[0]
        try:
            password = line.split(" ")[1]
            verify = argon2_hasher.verify(hash, password)
            if verify:
                print(f"Password: {m} matches the hash.")
                break
        except:
            continue
```

![](f41a86e0cd1852fd77a05dd320a89312.webp)

结果为`chewhaoN@6087`

## 17.请分析检材2Linux系统，chrome浏览器插件存放的令牌的名称为

![](522249d1e07dde0f92d7a15b051969b7.webp)

结果为`chenhaoren`

## 18.请分析检材2Linux系统，该检材Linux系统浏览器插件存放的令牌在2022-05-12 00:54:10时的令牌为

修改系统时间即可

![](f14e3011fa62f4609b17626306b3dbec.webp)

结果为`080000`

# 服务器取证

## 1.请分析检材3，该操作系统版本号为

![](8d9b197b2561cbf35cad4908dc65a7dd.webp)

结果为`Ubuntu 24.04`

## 2.请分析检材3，该主机名为

![](3127c665d125eebc56d03a009883a1d5.webp)

结果为`api-server-2`

## 3.请分析检材3，该ens33网卡IP地址为

![](5146d34d00d4a66c988cfb9151b5ae40.webp)

结果为`172.16.10.254`

## 4.请分析检材3，操作系统登录使用了第三方身份验证，该技术为

正常仿真绕密后无法登录，然后看到这一系列题目，找到了`/etc/pam.d/common-auth`配置文件

![](925dc0420e51881a903f5cb1fae2ba4e.webp)

结果为`pam_pwdfile`

## 5.请分析检材3，该身份验证的加密算法为？

结果为`Bcrypt`

## 6.请分析检材3，该保存king用户密码的文件名为？

结果为`my_two_factor_pwdfile`

## 7.请分析检材3，尝试爆破king用户，其密码为(king字母加3个数字)？

看一下确实是Bcrypt，直接python掩码跑一遍就行

![](c8520dcc57e92085fc349c7e4dbd347c.webp)

```python
import bcrypt

for i in range(1000):
    pwd = f'king{str(i).zfill(3)}'
    target_hash = "$2a$10$V/8GUI5aTNSnbFodPjP7Zu6vCFSXmvdd9oKHGtWv/vbT3Q4LLTCcW"
    if bcrypt.checkpw(pwd.encode(), target_hash.encode()):
        print(f"Password found: {pwd}")
        break
# king110
```

结果为`king110`

## 8.请分析检材3，该WEB-API配置的 MySQL 数据库服务器地址为

要ssh连接，需要改网卡配置，改ip地址和网关，不赘述了

看一下容器内容，找到配置文件，这边读取还是从变量里读的

![](f510c6878b6df6b7393c7f6377330732.webp)

`docker inspect d4`

![](e5b8b211ddf752611dd720504d11b0d2.webp)

结果为`172.16.10.200`

## 9.请分析检材3，其中用于 WEB-API 测试的流量包文件名为

![](8b818e494f9ca7c8bbdd4db387a0d366.webp)

结果为`test.pcap`

## 10.请分析检材3流量包，统计其中 admin 用户成功登录的次数为

文件在`/home/king/test/test.pcap`

http.response.code==200过滤，然后追踪流，连着3个成功登录

![](989c3bdcb35ea10ff7378511ac5eccac.webp)

结果为`3`

## 11.请分析检材3流量包，找出用户最后一次查看的商品型号为

继续查看上面的流，就能看到

![](78269ffd8feb56b50523fa75a5a92f15.webp)

结果为`hx-101`

## 12.请分析检材3WEB-API，该容器镜像ID为(前六位)

![](d147b96bd643468d0c0b66653972cf4c.webp)

结果为`996a32`

## 13.请分析检材3WEB-API，该容器的核心服务编程语言为

![](bbc1f2b2df92cb46266ac953909f1d62.webp)

结果为`nodejs`

## 14.请分析检材3WEB-API，该容器所用域名为

有一个nginx容器，工作目录是`/home/king/nginx-proxy`，看一下就出

![](c8aa0bf366b77b83c1fc0a7afa2415da.webp)

结果为`api-server.com`

## 15.请分析检材3WEB-API，该容器日志文件名(access\_log)为

见上题

结果为`api-server-access.log`

## 16.请分析检材3WEB-API，该容器的FLAG2的接口URL为

先看到接口名

![](4fd96df87b2b1c0cfa79ff2e9e518192.webp)

然后找到接口路径

![](b99f3f8f2c334a167b331968b8695c3c.webp)

结果为`/api/auth/flag2`

## 17.请分析检材3WEB-API，该容器的服务运行状态的接口URL为

![](1923fb47b87c3a59796402e5796c5261.webp)

结果为`/api/health`

## 18.请分析检材3WEB-API，该容器中访问FLAG2接口后，会提示需要在什么调试器下运行

![](5b8b15ec36fa8344e5f5cc518d8130a6.webp)

结果为`gdb`

## 19.请分析检材3WEB-API，该容器的admin用户的登录密码为

流量包里就看到了

结果为`zhaohong666`

## 20.请分析检材3WEB-API，该容器的数据库内容被SO所加密，该SO文件名为

![](4ef17deb1912c4e3369a639fc97f1381.webp)

结果为`libjiami.so`

## 21.请继续分析上题SO文件，该文件的编译器类型为

![](85ebdade922925023b8c36193a5531f9.webp)

结果为`gcc`

## 22.请继续分析上题SO文件，在SO文件的encrypt函数中，该加密算法为

![](61ce485620f932cb1e5c5ea7b960ee5d.webp)

结果为`AES-256-CBC`

## 23.请继续分析上题SO文件，尝试分析getAeskey函数，该KEY值为

接下来最好是用gdb直接调试拿数据，需要先连接数据库，先把数据库的容器打开，可以观察到ip是`172.17.0.2`

![](d4d33b8bc42beb3589ea50788a89f89c.webp)

但是我们要连的数据库是`172.16.10.200`，这里不在同一个网段，是不通的

不过可以发现，数据库容器映射的端口出来，并且监听0.0.0.0，所以可以让容器连接我们的ip地址即可

webapi用的是172.18这个

![](e6aaef0bdd1caf1c776fe0ec417eb181.webp)

刚好webapi是通过docker-compose启动的，所以直接停掉，改配置文件，然后docker compose up启动

![](c1d3e2bf87f3cf7551f6e8c2b678e2a9.webp)

![](ddb3d0ef7b0f330e0c351167b92271e3.webp)

查看日志发现连接数据库成功

![](7860d6853912b04896b1d88a4f97bc8a.webp)

进入容器进行调试，容器里没啥东西，直接调试进程1即可

![](04b0c0ad73890b0e46f073aab56d1f9d.webp)

调用函数并获得返回的地址，查看地址数据，这里查看32个字节，因为加密算法是`aes-256-cbc`，密钥长度是256位

![](18076dfb0692854f9cac5888400d71ce.webp)

拿到密钥

![](3e71da7cca77f8fa88be613b7d570bb4.webp)

结果为`zhaohongzhaohongzhaohongzhaohong`

## 24.请继续分析上题SO文件，尝试分析get\_flag1函数，该返回值为

![](401475b26e606ef345032c4380b91b50.webp)

结果为`flag1{hong112233}`

## 25.请继续分析上题SO文件，尝试分析get\_flag2函数，该返回值为

![](401475b26e606ef345032c4380b91b50.webp)

结果为`flag2{hong}`

## 26.请继续分析上题SO文件，尝试分析decrypt函数，该密文dnJXwBR4qc+1Y4WB6ZxR0A==的明文为

![](f52bcfa09a8917a267fe21a5ddcf4c9c.webp)

直接传参数进去看看效果

![](e790d72b927653fb163cce61f5bb91fa.webp)

结果为`FICerisgood`

## 27.请分析检材3数据库，在 products 表中，统计商品型号的种类数量（例如以 ZK、CW 等为前缀的型号）

之前已经知道用户名密码了，直接连上去查询，然后解密，由于是cbc模式，还要获取iv，这个简单直接拿了

![](9cf7b2e85d353d84e59c2479c4a2422c.webp)

```python
import pymysql
import pandas as pd
from Crypto.Cipher import AES
from Crypto.Util.Padding import unpad
import base64
import json

def decrypt_aes(ciphertext):
    ciphertext = base64.b64decode(ciphertext)
    key = b'zhaohongzhaohongzhaohongzhaohong'
    iv = b'0123456789012345'
    cipher = AES.new(key, AES.MODE_CBC, iv)
    padded_data = cipher.decrypt(ciphertext)
    decrypted = unpad(padded_data=padded_data, block_size=AES.block_size)
    return decrypted.decode('utf-8')

conn = pymysql.connect(
    host='192.168.71.24',
    port=3306,
    user='root',
    passwd='7001',
    db='product_db',
    charset='utf8'
)

cursor = conn.cursor()
sql = 'select * from products;'
df = pd.read_sql(sql, conn)
df["name_encrypted"] = df["name_encrypted"].apply(decrypt_aes)
df["description_encrypted"] = df["description_encrypted"].apply(decrypt_aes)
df["price_encrypted"] = df["price_encrypted"].apply(decrypt_aes)
df["category_encrypted"] = df["category_encrypted"].apply(decrypt_aes)
df["additional_data_encrypted"] = df["additional_data_encrypted"].apply(decrypt_aes)

print(f"商品型号的种类数量：{len(set([v.split('-')[0] for v in df['name_encrypted'].to_list()]))}")
cnt = 0
total_price = 0
for idx,row in df.iterrows():
    if row['name_encrypted'].split('-')[0] == 'zk':
        total_price += float(row['price_encrypted'])
        if json.loads(row['additional_data_encrypted'])['color'] == '灰色':
            cnt += 1

print("灰色的zk型号商品数量：", cnt)
print("zk型号商品总价格：", total_price)

# 商品型号的种类数量：5
# 灰色的zk型号商品数量： 29
# zk型号商品总价格： 106450.36000000002
```

结果为`5`

## 28.请分析检材3数据库，在 products 表中，统计型号为 “ZK” 且颜色为灰色的商品的数量

结果为`29`

## 29.请分析检材3数据库，在 products 表中，统计型号为 "ZK" 的总销售额（金额只保留整数部分，不进行四舍五入）

结果为`106450`

# 物联网取证

## 1.请分析检材4，该检材的系统版本号为

仿真，其中bios和kernel需要下载，如果你有安装火眼或者盘古石仿真，那bios应该在电脑里能找到，kerner就去官网下载

另外关于网络这块，我也不太懂，不过可以通过安装openvpn的方式来获得tap网卡，改名后讲本机网卡的网络共享给他

![](c4d2ac90158c5af28a4c4706e745d5d2.webp)

这样仿真起来后，软路由就会有和本机同样的ip

```python
./qemu-system-aarch64.exe -m 512 -cpu cortex-a72 -M virt -nographic -bios "C:\Program Files (x86)\PanSafe\SafeVM\bios\QEMU_EFI.fd" -kernel "G:\openwrt-22.03.0-armvirt-64-Image" -drive if=none,file="G:\router.qcow2",format=qcow2,id=hd0 -device virtio-blk-device,drive=hd0 -append "root=/dev/vda" -net nic -net tap,ifname=tap0
```

![](5921132cb6723f88f024721aabd25db7.webp)

结果为`24.10.0`

## 2.请分析检材4，该检材的lan口ip为

`cat /etc/config/network`

![](2e00e05934d80064694458aa044a61f0.webp)

结果为`192.168.31.1`

## 3.请分析检材4，该检材Overlayfs分区的大小为多少KB

![](dd94ebfedb5efd407179a483592cc124.webp)

结果为`8292024`

## 4.请分析检材4，该检材中VPN网络私钥为

`cat /etc/config/network`

![](238313723dcedf7aa384b9fae0ece93f.webp)

结果为`SLkCLyRhrkWIFgJWfEd0B7s99FYWJf9PUV+scj3Vw3U=`

## 5.请分析检材4，嫌疑人交代其开发了一款专门用于收集其售出摄像头信息的服务程序。请问该摄像头信息收集服务程序编译器版本为？

如何获得这个文件？

我是通过共享网卡之后，scp上传到我自己的服务器当中的

![](a7d03e5a4f103a9f43fee1edfebfe914.webp)

这样我就能从服务器里拿到这个文件

![](9d4843d2f6bec1d69a5937c892116740.webp)

结果为`13.3.0`

## 6.请分析检材4，该摄像头信息收集程序支持的运行参数（命令行参数）数量为多少

![](e1a335b4794ed0676e71dee711ea1224.webp)

结果为`2`

## 7.请分析检材4，该摄像头信息收集程序使用了什么算法进行加密

A.MD5 B.AES C.BASE64 D.DES

![](98b10b4a24f13a65a3a97b00fee0c25e.webp)

结果为`BC`

## 8.请分析检材4，该摄像头信息收集程序所使用的数据库文件名为

![](e20d47617cb048e7bab5c99a31de79e5.webp)

结果为`collected.txt`

## \*9.请分析检材4，该摄像头信息收集程序收集了以下哪些摄像头信息？

A.IP 地址 B.摄像头密码 C.备注信息 D.电话号码

aes密钥是hex`0123456789ABCDEF`，但是没有找到数据文件

![](da7f418f0b6f7c3151410f605859d36b.webp)

# APP逆向

## 1.请分析检材5，该检材的包名为

![](bae05fa5d1f87fb0d2fe2039ab5974c0.webp)

结果为`com.forensix.cam`

## 2.请分析检材5，该检材的签名证书 MD5 值为

![](2560c82b2ee8ac9b93dee67ecb5df8d9.webp)

结果为`7b1963b70fbac57a50836e9a044d0029`

## 3.请分析检材5，在尝试抓包登录 APP 时，登录请求中提交的参数包括：（请使用比武U盘中提供的智能家居账号密码进行登录抓包）

A.devicename B.password C.id D.flag

![](30376c3ca98dc672c51240318016122c.webp)

结果为`BCD`

## 4.请分析检材5，通过抓包分析登录请求，获取到的 flag 参数的值为

![](13a05774aaf790effdc774a4a550d41b.webp)

扣出来跑一下就行了

![](7f1c5b36887abdae2d3f041b06a3e12a.webp)

结果为`05d8cccb5f`

## 5.请分析检材5，该 APK 登录请求中携带了一个远程调证 ID，分析该请求并提取该 ID，统计其长度为（请提取该 ID 并在比武平台中进行调证，准备进入下一阶段分析，可参考比武 U 盘中的手册）

跟上面那个一样的逻辑，这里是输入的md5的前6位

![](3c5293500d63558d87d6d469466b7496.webp)

结果为`6`

## 6.请分析检材5，在登录成功后，应用会跳转至 “欢迎使用 forensix” 界面。该界面对应的 Activity 类的完整类名为

从这里跳转的

![](7072dcc6556fa9b30d65c862f00231f7.webp)

这是第6个

![](77553ed9f4a870dc7424a23b51542e7b.webp)

![](30fb2da876cde0be98758be5f6557582.webp)

![](a1318ef86dd18cd3de0770a203063898.webp)

结果为`com.forensix.cam.activity.c75e3a8b2d`

## 7.请分析检材5，分析上述 Activity 类后，发现其内部定义的 TAG 常量值为：

![](7d3b8809ce7795815236136ed097c551.webp)

结果为`222`

## \*8.请结合互联网分析APP调证检材，该检材系统版本号为(完成调证后，可参考比武 U 盘中的手册，在云实验室中继续完成取证任务)

## \*9.请结合互联网分析APP调证检材，该检材系统内FLAG值为(完成调证后，可参考比武 U 盘中的手册，在云实验室中继续完成取证任务)

# 综合分析

## 1.请综合分析，陈某进行了那些操作

A.VC加密Linux系统 B.VC加密Windows系统 C.VC加密文件 D.VC加密系统容器

pc有加密一个win系统分区，里面有存一个加密容器

结果为`BC`

## \*2.请综合分析，陈某没有使用过以下那种方式安装数据库

A.编译安装 B.包管理器安装 C.容器安装 D.单文件

容器是mysql，单文件是sqlite

## 3.请综合分析，陈某使用过以下那些系统

A.Windows B.MacOS C.Debian D.CentOS E.Fedora

结果为`AC`

## 4.请综合分析，以下说法正确的是

1.陈某将正确的助记词藏在了Linux中

2.陈某将正确的助记词藏在了windows中

3.陈某电子数据中保留了孙某的欠条

4.陈某电子数据中保留了王某的欠条

5.陈某使用JAVA搭建后台接口

6.陈某和“香格里拉大酒店”有关"

结果为`146`

## 5.请综合分析，陈某现有电子数据没有以下那个Linux内核版本

A.4.14-arm B.6.6-arm C.4.15-x64 D.6.8-x64

结果为`C`

## \*6.请综合分析，陈某做为壁纸的邪影芳灵原图的sm3值为

## \*7.请结合分析，陈某的真实GitHub密码为

手机里这个app

![](186887b92f9f05a7cde090dc333fab63.webp)

数据库里存了hash

![](5a781cc6e22e3c523dade84c00c114f5.webp)
