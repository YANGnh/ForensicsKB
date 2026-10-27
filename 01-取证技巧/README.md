# 取证技巧 · 方法与工具速查

> 由 tools/build-index.ps1 自动生成（2026-10-27 15:10），禁止手改。

共 20 篇，按 12 个主题目录组织。文档内图片为相对路径；截图内容可先查 ocr/ 同名文本（L1 检索层），再决定是否看图（L2 视觉层）。

## 主题目录

| 目录 | 篇数 |
|---|---|
| 01-内存取证 | 1 |
| 02-网络取证 | 3 |
| 03-密码加密 | 2 |
| 04-隐写文件 | 1 |
| 05-应用分析 | 3 |
| 06-数据库 | 1 |
| 07-服务器云 | 2 |
| 08-手机取证 | 1 |
| 09-介质磁盘 | 1 |
| 10-日志分析 | 1 |
| 11-工具速查 | 2 |
| 99-培训记录 | 2 |

## 全部文档

| 文档 | 类型 | 标签 | 图 | 状态 | 摘要 |
|---|---|---|---|---|---|
| [01-内存取证/内存分析.md](01-内存取证/内存分析.md) | technique | 内存取证 Volatility 注册表 | 0 | 完整 | （转载）Volatility 2 与 Volatility 3 常用插件命令对照速查：进程/网络/注册表/文件/恶意代码检测 |
| [02-网络取证/网络流量分析.md](02-网络取证/网络流量分析.md) | technique | 网络流量 Wireshark MySQL CyberChef SQL注入 | 1 | 完整 | 一句话木马、MySQL 流量与 SQL 注入（updatexml/outfile）流量特征过滤要点，附 CyberChef 换行替换技巧 |
| [02-网络取证/Cobaltstrike流量解密.md](02-网络取证/Cobaltstrike流量解密.md) | technique | 网络流量 加解密 CobaltStrike | 14 | 完整 | CobaltStrike Beacon 流量解密：无/有 beacon_keys 两场景，URI 校验和判架构、CSthing 解密配置、密钥解析解 cookie |
| [02-网络取证/WireShark分析实战手册.md](02-网络取证/WireShark分析实战手册.md) | technique | 网络流量 Wireshark SQL注入 | 0 | 完整 | Wireshark 实战手册：过滤器语法、TCP/HTTP/DNS/TLS 协议分析、恶意流量与攻击模式检测、tshark 命令行用法 |
| [03-密码加密/加解密.md](03-密码加密/加解密.md) | technique | hashcat VeraCrypt CyberChef 加解密 | 1 | 完整 | VeraCrypt 容器密码 hashcat 掩码爆破（-m 13721，dd 导出哈希）及 CyberChef 替换换行处理技巧 |
| [03-密码加密/hashcat wiki.md](03-密码加密/hashcat wiki.md) | reference | hashcat 加解密 VeraCrypt MySQL Telegram | 0 | 参考 | （转载）hashcat 官方 Example hashes 整站速查：哈希模式号与示例，覆盖 VeraCrypt/Telegram/MySQL 等类型 |
| [04-隐写文件/常见文件文件头和隐写术总结.md](04-隐写文件/常见文件文件头和隐写术总结.md) | technique | 隐写术 WinHex 010Editor | 4 | 完整 | 常见文件头文件尾汇总与隐写术总结：图片 LSB/PNG 结构/DCT 隐写、音频与文档隐写及检测工具 |
| [05-应用分析/程序功能分析.md](05-应用分析/程序功能分析.md) | technique | 程序功能分析 IDA 中文乱码 | 0 | 待完善 | IDA Pro 中文字符串不显示问题解决：修改 ida.cfg 的 CULTURE=all 与 NameChars 配置 |
| [05-应用分析/小众APK分析.md](05-应用分析/小众APK分析.md) | technique | APK分析 手机取证 数据库取证 SQLite 小众APP | 0 | 待完善 | 小众 App 取证数据定位速查：米家、高德、鸽哒等 App 的数据库与数据文件存储路径 |
| [05-应用分析/APK分析.md](05-应用分析/APK分析.md) | technique | APK分析 JADX blutter Frida 手机取证 | 0 | 完整 | APK/Flutter 逆向技巧集：blutter 分析 Flutter 应用、jadx 反编译、Frida 动态调用/改返回值，及按 Dex 头判断安卓版本 |
| [06-数据库/数据库分析.md](06-数据库/数据库分析.md) | technique | 数据库取证 MySQL Docker Redis phpMyAdmin | 0 | 完整 | MySQL 取证手册：用户授权与远程权限、skip-grant-tables 绕过/重置 root 密码（Windows/Linux/Docker 环境） |
| [07-服务器云/服务器分析.md](07-服务器云/服务器分析.md) | technique | 服务器取证 MySQL Docker K8s 数据库取证 | 5 | 完整 | 服务器取证综合速查：jasypt 解密、jar 包启动配置、宝塔面板、MySQL 还原、K8s 证书续期与 Laravel bcrypt 盐值分析 |
| [07-服务器云/K8s分析.md](07-服务器云/K8s分析.md) | technique | K8s kubectl 云原生 服务器取证 | 0 | 完整 | K8s 集群取证 kubectl 命令速查：查看 Pod/Service 详情与端口映射 |
| [08-手机取证/手机取证分析.md](08-手机取证/手机取证分析.md) | technique | 手机取证 APK分析 数据库取证 安卓 | 0 | 完整 | 安卓手机取证路径速查：目录结构、模拟器 data 还原、蓝牙配置与设备名称/内核版本文件位置 |
| [09-介质磁盘/介质分析.md](09-介质磁盘/介质分析.md) | technique | 磁盘取证 内存取证 加解密 VeraCrypt Volatility | 0 | 完整 | 磁盘与内存取证杂项技巧集：Vol3 提取哈希解密 Windows 登录密钥、VHD 挂载、文件头恢复、EFS 加解密、星号密码查看等 |
| [10-日志分析/Windows日志事件ID表.md](10-日志分析/Windows日志事件ID表.md) | technique | 日志分析 注册表 Windows日志 事件ID | 0 | 完整 | Windows 安全审核日志事件 ID 对照表：按帐户管理、登录/注销、对象访问、策略更改等类别列出 ID 及含义 |
| [11-工具速查/取证软件使用.md](11-工具速查/取证软件使用.md) | technique | WinHex X-ways FTK Imager JADX JEB | 0 | 完整 | 常见取证软件用途速查：WinHex/X-ways/FTK Imager 磁盘镜像、JADX/JEB APK 逆向、BurpSuite 抓包、Foremost 隐写提取等 |
| [11-工具速查/正则表达式.md](11-工具速查/正则表达式.md) | technique | 日志分析 正则表达式 数据提取 | 0 | 完整 | 正则表达式速查：手机号、邮箱、IP、URL、身份证号、QQ 等常见数据的提取与校验正则 |
| [99-培训记录/20230515美亚培训.md](99-培训记录/20230515美亚培训.md) | training | 培训 服务器取证 数据库取证 日志分析 MySQL | 0 | 完整 | 2023 美亚柏科培训记录：服务器取证要点，含 Web 中间件配置、Docker 数据提取、MySQL 密码绕过与常用命令 |
| [99-培训记录/20240716鉴定所培训.md](99-培训记录/20240716鉴定所培训.md) | training | 培训 手机取证 APK分析 加解密 日志分析 | 1 | 完整 | 2024 鉴定所培训杂记：安卓 ID 与 VMOS 云手机、iOS 升级日志、比特币交易查询、openssl des3 解密及 MySQL 导入等技巧 |