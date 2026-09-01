---
title: "Wireshark 分析实战手册"
type: technique
category: "网络取证"
competition: ""
year: ""
stage: ""
mode: ""
tags: [网络流量, Wireshark, SQL注入]
images: 0
status: "完整"
source: "原创"
created: 0000-00-00
updated: 2026-09-01
summary: "Wireshark 实战手册：过滤器语法、TCP/HTTP/DNS/TLS 协议分析、恶意流量与攻击模式检测、tshark 命令行用法"
---
# Wireshark 分析实战手册

主要内容包括：

基础操作

- 启动、捕获、导航快捷键
过滤器详解
- 显示过滤器和捕获过滤器的详细语法
协议分析
- TCP、HTTP、DNS、TLS等协议的专门分析技巧
网络故障排查
- 连接问题、性能问题、丢包分析
安全分析
- 恶意流量检测、攻击模式识别、数据泄露检测
性能优化
- 提高捕获和分析效率的技巧
导出与统计
- 数据导出和统计报告生成
命令行工具
- tshark的使用方法和批处理脚本

# 基础操作

## 导航快捷键

- **查找**: `Ctrl+F`
- **查找下一个**: `Ctrl+N`
- **前往数据包**: `Ctrl+G`
- **标记数据包**: `Ctrl+M`
- **放大**: `Ctrl++`
- **缩小**: `Ctrl+-`

## IP地址过滤

### 特定源IP

ip.src == 192.168.1.100

### 特定目标IP

ip.dst == 192.168.1.1

### IP范围

ip.addr == 192.168.1.0/24

### 排除特定IP

!(ip.addr == 192.168.1.1)

## 端口过滤

### 特定端口

tcp.port == 80

### 端口范围

tcp.port >= 1000 and tcp.port <= 2000

### 常用端口

tcp.port == 22    # SSH

tcp.port == 25    # SMTP

tcp.port == 53    # DNS

tcp.port == 80    # HTTP

tcp.port == 443   # HTTPS

tcp.port == 3389  # RDP

# 过滤器详解

## HTTP专用过滤器

### HTTP方法

http.request.method == "GET"

http.request.method == "POST"

### HTTP状态码

http.response.code == 200

http.response.code == 404

http.response.code == 500

### HTTP主机

http.host == "www.example.com"

### HTTP用户代理

http.user_agent contains "Chrome"

### HTTP内容类型

http.content_type contains "json"

### HTTP请求URI

http.request.uri contains "/api/"

### HTTP响应时间

http.time > 1.0

## 高级过滤技巧

### 逻辑操作符

http and tcp.port == 80

http or https

not dns

### 括号分组

```
(tcp.port == 80 or tcp.port  443) and ip.src == 192.168.1.100
```

### 字符串匹配

tcp contains "password"

http contains "admin"

### 正则表达式

http.host matches ".*\\.com$"

### 时间过滤

frame.time >= "2024-01-01 00:00:00"

## 捕获过滤器 (Capture Filters)

基于Berkeley Packet Filter(BPF)语法：

### 捕获特定主机

host 192.168.1.1

### 捕获特定端口

port 80

### 组合条件

host 192.168.1.1 and port 80

not port 22

# 协议分析

## TCP分析

- **TCP流跟踪**: 右键数据包 → Follow → TCP Stream
- **TCP重传**: `tcp.analysis.retransmission`
- **TCP重复ACK**: `tcp.analysis.duplicate_ack`
- **TCP窗口满**: `tcp.analysis.zero_window`
- **TCP重置**: `tcp.flags.reset == 1`

## HTTP分析

### 查看完整HTTP对话

http.request or http.response

### HTTP错误

http.response.code >= 400

### 大文件传输

http.content_length > 1000000

### 慢速响应

http.time > 2.0

## DNS分析

### DNS查询

dns.flags.response == 0

### DNS响应

dns.flags.response == 1

### DNS错误

dns.flags.rcode != 0

### 特定域名查询

dns.qry.name contains "example.com"

## TLS/SSL分析

### TLS握手

tls.handshake

### TLS证书

tls.handshake.certificate

### TLS警报

tls.alert

### 特定TLS版本

tls.record.version == 0x0303  # TLS 1.2

# 网络故障排查

## 连接问题诊断

1. **TCP连接建立**: 查找SYN, SYN-ACK, ACK三次握手
2. **连接重置**: 过滤`tcp.flags.reset == 1`
3. **连接超时**: 查找重传`tcp.analysis.retransmission`

### 

## 性能问题分析

### 慢速查询

dns.time > 0.1

### HTTP响应时间

http.time > 1.0

### TCP窗口问题

tcp.analysis.zero_window

tcp.analysis.window_update

## 丢包分析

### TCP重传

tcp.analysis.retransmission

### 乱序数据包

tcp.analysis.out_of_order

### 重复ACK

tcp.analysis.duplicate_ack

## 常用统计信息

- **Statistics → Protocol Hierarchy**: 协议分布
- **Statistics → Conversations**: 会话统计
- **Statistics → Endpoints**: 端点统计
- **Statistics → I/O Graph**: 流量图表

# 安全分析

## 恶意流量检测

### 可疑端口连接

```
tcp.port == 1337 or tcp.port == 31337
```

### 大量连接尝试

```
tcp.flags.syn == 1 and tcp.flags.ack == 0
```

### DNS隧道检测

dns.qry.name.len > 50

### 异常用户代理

http.user_agent contains "bot" or http.user_agent contains "crawler"

## 常见攻击模式

### SQL注入尝试

http.request.uri contains "union" or http.request.uri contains "select"

### XSS尝试

http.request.uri contains "<script>" or http.request.uri contains "javascript:"

### 目录遍历

http.request.uri contains "../"

### 扫描行为

```
tcp.flags.syn == 1 and tcp.flags.ack == 0
```

## 数据泄露检测

### 明文密码传输

tcp contains "password=" or tcp contains "passwd="

### 敏感信息

tcp contains "credit" or tcp contains "ssn" or tcp contains "social"

### 文件上传/下载

```
http.request.method == "PUT" or http.request.method == "POST"
```

# 性能优化

## 提高捕获性能

1. **使用捕获过滤器**: 减少不需要的数据包
2. **增加缓冲区大小**: Capture → Options → Buffer size
3. **写入多个文件**: 避免单个文件过大
4. **关闭名称解析**: View → Name Resolution

### 

## 分析大文件技巧

1. **使用显示过滤器**: 只显示相关数据包
2. **时间范围过滤**: 分段分析
3. **导出特定数据**: File → Export Objects
4. **使用tshark**: 命令行工具处理大文件

# 导出与统计

## 导出对象

- **File → Export Objects → HTTP**: 导出HTTP对象
- **File → Export Objects → DICOM**: 导出DICOM文件
- **File → Export Objects → SMB**: 导出SMB文件

## 流跟踪导出

- **Follow Stream**: 右键数据包选择跟踪流
- **Save As**: 保存完整对话内容

## 统计报告

### 生成统计报告

Statistics → Summary          # 捕获摘要

Statistics → Protocol Hierarchy  # 协议层次

Statistics → Conversations    # 对话统计

Statistics → Endpoints       # 端点统计

Statistics → Packet Lengths  # 数据包长度分布

# 命令行工具(tshark)

## 基本用法

### 捕获网络流量

tshark -i eth0

### 读取pcap文件

tshark -r capture.pcap

### 应用显示过滤器

tshark -r capture.pcap -Y "http"

### 指定输出字段

tshark -r capture.pcap -T fields -e ip.src -e ip.dst -e http.host

## 高级用法

### 输出为JSON格式

tshark -r capture.pcap -T json

### 导出HTTP对象

tshark -r capture.pcap --export-objects http,/tmp/objects/

### 统计信息

tshark -r capture.pcap -z conv,tcp

tshark -r capture.pcap -z endpoints,ip

### 协议层次统计

tshark -r capture.pcap -z io,phs

### 时间窗口分析

tshark -r capture.pcap -Y "frame.time >= \"2024-01-01 00:00:00\""

## 批处理脚本示例

#!/bin/bash

### 分析HTTP流量脚本

echo "=== HTTP主机统计 = =="

tshark -r $1 -Y "http.request" -T fields -e http.host | sort | uniq -c | sort -nr

echo "=== HTTP状态码统计 = =="

tshark -r $1 -Y "http.response" -T fields -e http.response.code | sort | uniq -c | sort -nr

echo "=== 用户代理统计 = =="

tshark -r $1 -Y "http.request" -T fields -e http.user_agent | sort | uniq -c | sort -nr

# 实用技巧总结

## 快速分析检查清单

1. **概览**: Statistics → Summary 查看基本信息
2. **协议分布**: Statistics → Protocol Hierarchy
3. **主要通信方**: Statistics → Conversations
4. **异常检查**: 查找错误、重传、异常状态码
5. **时间分析**: I/O Graph 查看流量模式
6. **内容检查**: Follow Stream 查看具体通信内容

## 常见问题解决

- **中文乱码**: Edit → Preferences → Protocols → HTTP → 设置字符编码
- **DNS解析慢**: View → Name Resolution → 关闭网络名解析
- **内存不足**: 使用显示过滤器减少显示的数据包数量
- **时间不准**: View → Time Display Format 调整时间显示

## 颜色规则自定义

- **View → Coloring Rules**: 自定义数据包颜色
- 常用颜色规则：
  - 红色：TCP错误 `tcp.analysis.flags`
  - 黄色：HTTP错误 `http.response.code >= 400`
  - 绿色：DNS `dns`
  - 蓝色：HTTP `http`

这份手册涵盖了Wireshark的主要使用技巧，从基础操作到高级分析，希望能帮助您更高效地进行网络分析。建议收藏备用，并在实际使用中不断实践和完善。

举个例子：有个pcap分析题。某单位被攻击了，请分析以下网络安全事件的流量包，并解答以下问题，黑客利用的Github开源项目的名字是？提交答案格式：flag{项目名称}（如有字母请全部使用小写）
答：
HTTP分析过滤器
http contains "github"
http.host contains "github"
http.request.uri contains "github"

***

🔎 1. 识别扫描与探测活动

**SYN 扫描：过滤`tcp.flags.syn == 1 and tcp.flags.ack == 0`。观察大量SYN包发往不同目标端口（来自同一源IP），且没有后续的ACK（或很快收到RST）。查看目标端口序列（是否连续？常见高危端口？）。

**Connect 扫描：寻找完整的TCP三次握手 (`tcp.flags.syn == 1`, `tcp.flags.syn == 1 and tcp.flags.ack == 1`, `tcp.flags.ack == 1`) 出现在大量非常用端口上。攻击者尝试建立完整连接。

**UDP 扫描：过滤 udp。观察大量UDP包发往不同目标端口。关键看是否有响应（ICMP Port Unreachable `icmp.type == 3 and icmp.code == 3` 表示端口关闭，无响应可能端口开放或被过滤）。

**主机发现 (Ping Sweep): 过滤 `icmp.type == 8` 或 `arp`。观察ICMP Echo Request (Ping) 或 ARP Request 广播到多个目标IP。

**操作系统指纹识别： 分析TCP SYN包的初始TTL值、TCP窗口大小、TCP选项（如时间戳、MSS、窗口缩放因子、SACK许可）等细节。不同OS有不同默认配置。`tcp.options` 字段很有用。需与已知指纹库对比（非Wireshark内置功能，需经验或外部工具辅助分析）。

**服务版本探测： 观察扫描后，攻击者对开放端口发送的探测性载荷（例如，发送一个非标准的HTTP请求、SSH banner grab），并分析服务器的响应 (`tcp.dstport == `)。

🕵 2. 分析常见攻击流量

（1）DoS/DDoS:

**SYN Flood:  大量 `tcp.flags.syn == 1` 来自不同源IP（可能是伪造的）发往同一目标端口。目标服务器回应大量 `tcp.flags.syn == 1 and tcp.flags.ack == 1` (SYN-ACK) 但鲜有后续ACK (`tcp.flags.ack == 1`)，导致半开连接耗尽资源。结合**Statistics > Conversations > TCP** 查看目标IP的异常高连接数。

**UDP Flood:  大量UDP包（通常是大包）发往目标主机随机端口。过滤 `udp and ip.dst == `。

**ICMP Flood:  大量ICMP Echo Request (Ping) 发往目标。过滤 `icmp.type == 8 and ip.dst == `。

**反射/放大攻击 (如 NTP, DNS, SSDP):** 寻找大量响应包 (`udp`) 从合法的第三方服务器（如NTP服务器端口123，DNS服务器端口53）涌向受害者IP。这些响应包的大小远大于源请求包（放大）。过滤 `udp.srcport == ` 和 `ip.dst == `。

（2）中间人攻击 (MITM):

**ARP 欺骗/毒化:  在局域网中，寻找异常的ARP响应 (`arp.opcode == 2`)，声称自己是网关或其他重要主机的IP地址，但其MAC地址却是攻击者的。过滤 `arp` 并仔细检查ARP包的源MAC和IP地址是否匹配且符合预期。大量非请求的ARP应答也是可疑信号。

**DHCP 欺骗:  寻找非授权的DHCP服务器(`bootp`)。检查DHCP Offer (`bootp.option.dhcp == 2`) 或 ACK (`bootp.option.dhcp == 5`) 包，看其提供的网关、DNS服务器地址是否合法。

（3）可疑连接与数据渗漏:

**非标准端口上的已知协议:  例如在端口 8080、4444、6667 上看到 HTTP (`http`) 或 SSL/TLS (`tls`) 流量。过滤 `tcp.port == ` 并结合协议过滤。

**DNS 隧道:  大量异常的DNS请求(`dns`)，特别是TXT, NULL, A (指向长随机子域名) 类型，请求频率高，域名长且随机，响应数据大小异常。过滤 `dns` 并仔细查看查询名称和响应数据。

**HTTP/HTTPS 数据渗漏:  检查POST请求(`http.request.method == "POST"`) 到不常见或可疑域名，特别是上传大量数据的。检查URL和载荷内容（**注意合规性**）。对于HTTPS (`tls`)，虽然内容加密，但可以观察目标域名(`tls.handshake.extensions_server_name` - 需要解密或查看Client Hello) 和数据包大小/频率模式。

**反向Shell:  通常表现为内部主机向外部一个不常见IP/端口发起连接，并保持长时间静默或间歇性小数据传输（心跳），然后突然有较大数据传输（命令执行结果）。分析TCP会话 (`tcp.stream eq `) 的行为模式。

（4）恶意软件活动:

**C&C 通信:  寻找主机周期性连接特定IP/端口，传输小数据（心跳、指令）或大数据（窃取数据、下载模块）。分析TCP/UDP会话模式、目标IP/端口（查看威胁情报库）、协议（HTTP, HTTPS, DNS, Raw TCP/IP）。`tls` 连接的目标服务器名 (`tls.handshake.extensions_server_name`) 是关键线索。

**漏洞利用流量:  分析攻击载荷。寻找异常大的TCP/UDP包、特定格式的畸形包（可能导致缓冲区溢出）、包含已知Shellcode特征码（如 `\x90\x90\x90\x90` NOP sled, `\xff\xe4` jmp esp）的载荷。这需要深入协议解析和载荷检查。

**横向移动: 分析SMB、RDP、PsExec、WMI、SSH等协议流量，特别是内部主机之间非管理员发起的认证尝试（大量失败登录 `smb.nt_status != 0`），传递哈希，或使用可疑账户成功登录。

📥 3. 数据提取与深入分析

**导出对象： 从应用层协议中提取传输的文件。

- `File > Export Objects > HTTP...`：提取通过HTTP传输的文件（可执行文件、文档、图片等）。
- `File > Export Objects > SMB...`：提取通过SMB传输的文件。
- `File > Export Objects > FTP-DATA...`：提取通过FTP传输的文件。

**关键用途： 提取恶意软件样本、被窃取的文件、攻击者上传的Web Shell等。提取后务必使用沙箱或反病毒软件扫描！

**跟踪TCP流： 右键包 -> `Follow > TCP Stream`。将选定TCP会话的所有应用层数据（包括请求和响应）重组并显示在一个窗口里。**这是分析HTTP交互、Telnet/SSH命令、数据库查询、C&C通信等文本协议的核心方法！** 可以切换显示格式（ASCII, Hex, EBCDIC, C Arrays），并方便地过滤、搜索、导出整个会话内容。

**查看载荷 (Hex Dump)： 在包详情面板底部查看载荷的十六进制和ASCII表示。用于分析非文本协议、查找Shellcode、特定文件签名（Magic Number）等。

**分组字节： 在包详情面板中，Wireshark根据协议规范将原始字节解析为有意义的字段。深入理解这些字段（如IP头的TTL、Flags；TCP头的Seq/Ack、Flags、Window Size；HTTP头的各种字段）对分析异常行为至关重要。
