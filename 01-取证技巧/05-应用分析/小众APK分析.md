---
title: "小众 APK 分析"
type: technique
category: "应用分析"
competition: ""
year: ""
stage: ""
mode: ""
tags: [APK分析, 手机取证, 数据库取证, SQLite, 小众APP]
images: 0
status: "待完善"
source: "原创"
created: 0000-00-00
updated: 2026-09-01
summary: "小众 App 取证数据定位速查：米家、高德、鸽哒等 App 的数据库与数据文件存储路径"
---
# 小众 APK 分析

K# 米家

com.xiaomi.smarthome

### usrID

`/data/com.xiaomi.smarthome/databases/miio.db`

`shareuserrecord`表

`userId`字段

### 摄像头终端设备IP地址

`/data/com.xiaomi.smarthome/files/mmkv/smart.widget.base.data.info`

`localip`字段

# 高德地图

com.autonavi.minimap

### 头像

`/media/0/Android/data/com.autonavi.minimap/files/autonavi/avatar/`

# ai换脸神器

uni.UNI2DBD214_1

### 数据库

`/data/uni.UNI2DBD214_1/databases/ksadcache.db`

# 鸽哒

com.geda123.tio.chat

### 聊天数据库

`/data/com.geda123.tio.chat/databases/tio.db`

### 服务器数据库

`/data/com.geda123.tio.chat/databases/okgo.db`

# 95分

com.jiuwu

### 历史发布信息

`\data\com.jiuwu\files\mmkv\mmkv.default`

# 私密相册

com.didipp.appp

### 数据库

`/data/com.didipp.appp/databases/xm_safe2238152404.db`

### 储存文件路径

`/data/user/0/com.didipp.appp/files/`

# 随记备忘录

com.snmitool.freenote

### 数据库

`/data/data/com.snmitool.freenote/databases/data-todo`