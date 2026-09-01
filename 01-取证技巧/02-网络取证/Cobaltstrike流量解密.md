---
title: "CobaltStrike 流量解密"
type: technique
category: "网络取证"
competition: ""
year: ""
stage: ""
mode: ""
tags: [网络流量, 加解密, CobaltStrike]
images: 14
status: "完整"
source: "原创"
created: 0000-00-00
updated: 2026-09-01
summary: "CobaltStrike Beacon 流量解密：无/有 beacon_keys 两场景，URI 校验和判架构、CSthing 解密配置、密钥解析解 cookie"
---
# Cobaltstrike流量解密

### 1.没有.cobaltstrike.beacon\_keys

![image](2c760750a611b2bbc69cc580562cc225.webp)

第一步，找到uri，在这里面，TJvI就是uri。

```python
characters = 'TJvI'
total_sum = sum(ord(char) for char in characters)
remainder = total_sum % 256
print(f"对 256 取余的结果为: {remainder}")
# 93
#93对应为x64 ,92为x86,说明这个beacon是x64的
```

![image-20250727184053284](72280dd40d0d1570a76961f8d5dc94fd.webp)

![image-20250727184300532](e52a50e8f236f175df599a637ddab179.webp)

保存导出，生成

![image-20250727184428220](c11c1319131007c071dbcf063aec3859.webp)

这里我们通过如下脚本对beacon文件解密：

脚本获取：[https://github.com/minhangxiaohui/CSthing](https://github.com/minhangxiaohui/CSthing)

![image-20250727184522614](ed8041c4bd58ab6a804cf7778fe6292b.webp)

以下是解析结果：

```powershell
python 1768.py .\TJvI.vir

File: .\TJvI.vir
xorkey(chain): 0x744266ff
length: 0x0484002e
Config found: xorkey b'.' 0x00000000 0x000061cf
0x0001 payload type                     0x0001 0x0002 0 windows-beacon_http-reverse_http
0x0002 port                             0x0001 0x0002 12580
0x0003 sleeptime                        0x0002 0x0004 60000
0x0004 maxgetsize                       0x0002 0x0004 1048576
0x0005 jitter                           0x0001 0x0002 0
0x0007 publickey                        0x0003 0x0100 30819f300d06092a864886f70d010101050003818d00308189028181009cf1af3bffe8855bc30f10c1994ece58002e1795e76710f8b8a023006e1a6068943a4b5a6970d4a4f9ce942d2
9f3f032fb864a5b0389b6cd40de94ad67f13ea52221a2f94a1112b22bf4d4ca928f404b0b751a0a9c3d893062be8b31a90383b23a626b2c48bd2e5f80c0e7de7d6d5da81c53580a5730cf6b789e344b6284af6d020301000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0x0008 server,get-uri                   0x0003 0x0100 '192.168.27.132,/ca'
0x0043                                  0x0001 0x0002 0
0x0044                                  0x0002 0x0004 4294967295
0x0045                                  0x0002 0x0004 4294967295
0x0046                                  0x0002 0x0004 4294967295
0x000e SpawnTo                          0x0003 0x0010 (NULL ...)
0x001d spawnto_x86                      0x0003 0x0040 '%windir%\\syswow64\\rundll32.exe'
0x001e spawnto_x64                      0x0003 0x0040 '%windir%\\sysnative\\rundll32.exe'
0x001f CryptoScheme                     0x0001 0x0002 0
0x001a get-verb                         0x0003 0x0010 'GET'
0x001b post-verb                        0x0003 0x0010 'POST'
0x001c HttpPostChunk                    0x0002 0x0004 0
0x0025 license-id                       0x0002 0x0004 987654321
0x0024 deprecated                       0x0003 0x0020 'NtZOV6JzDr9QkEnX6bobPg=='
0x0026 bStageCleanup                    0x0001 0x0002 0
0x0027 bCFGCaution                      0x0001 0x0002 0
0x0047                                  0x0002 0x0004 0
0x0048                                  0x0002 0x0004 0
0x0049                                  0x0002 0x0004 0
0x0009 useragent                        0x0003 0x0100 'Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; WOW64; Trident/5.0; BOIE9;ENUS)'
0x000a post-uri                         0x0003 0x0040 '/submit.php'
0x000b Malleable_C2_Instructions        0x0003 0x0100 '\x00\x00\x00\x04'
0x000c http_get_header                  0x0003 0x0200
  Cookie
0x000d http_post_header                 0x0003 0x0200
  &Content-Type: application/octet-stream
  id
0x0036 HostHeader                       0x0003 0x0080 (NULL ...)
0x0032 UsesCookies                      0x0001 0x0002 1
0x0023 proxy_type                       0x0001 0x0002 2 IE settings
0x003a                                  0x0003 0x0080 '\x00\x04'
0x0039                                  0x0003 0x0080 '\x00\x04'
0x0037                                  0x0001 0x0002 0
0x0028 killdate                         0x0002 0x0004 0
0x0029 textSectionEnd                   0x0002 0x0004 0
0x002b process-inject-start-rwx         0x0001 0x0002 64 PAGE_EXECUTE_READWRITE
0x002c process-inject-use-rwx           0x0001 0x0002 64 PAGE_EXECUTE_READWRITE
0x002d process-inject-min_alloc         0x0002 0x0004 0
0x002e process-inject-transform-x86     0x0003 0x0100 (NULL ...)
0x002f process-inject-transform-x64     0x0003 0x0100 (NULL ...)
0x0035 process-inject-stub              0x0003 0x0010 'ä:\x1bcð\x97\x94÷M\x90©\x88\x9fzËw'
0x0033 process-inject-execute           0x0003 0x0080 '\x01\x02\x03\x04'
0x0034 process-inject-allocation-method 0x0001 0x0002 0
0x0030                                  0x0001 0x0002 1
0x0010 killdate_year                    0x0001 0x0002 0
0x004a                                  0x0003 0x0020 '¯t¥ºð\x97\x94ï>¥\x90äª\x13ºF\x81PAP¿ÆðØ>÷ßÆþ\x1döJ'
0x0011 killdate_month                   0x0002 0x0004 0
0x0000
Guessing Cobalt Strike version: 4.4 (max 0x004a)
```

`server,get-uri`就是心跳url，里面的cookie存放了加密过的受害端信息

![image-20250727184908184](bcc3038c120608eb7fe11a4321a4bef6.webp)

这个就是心跳包

```sh
fzNft/HiDaRFScnOwn2g5NB9q138fgyI0v9dyANERT4RiGREeZvWQKl74RlY+dE98/nm28esJTI5LPxxrQIo1qtX5/yyVeuuYqm6PfWbPOOPx3CtmUyHz0WQEs+Sk2sw3vAEX/jZOcrqgUnRa9
```

尝试对cookie解密,私钥存放在`.cobaltstrike.beacon_keys`文件里,如果题目给了这个文件就可以直接拿来解密，但是本题没有给出  
于是尝试手解rsa

我们找到上文的publickey：

```undefined
0x0007 publickey                        0x0003 0x0100 30819f300d06092a864886f70d010101050003818d00308189028181009cf1af3bffe8855bc30f10c1994ece58002e1795e76710f8b8a023006e1a6068943a4b5a6970d4a4f9ce942d2
9f3f032fb864a5b0389b6cd40de94ad67f13ea52221a2f94a1112b22bf4d4ca928f404b0b751a0a9c3d893062be8b31a90383b23a626b2c48bd2e5f80c0e7de7d6d5da81c53580a5730cf6b789e344b6284af6d020301000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
```

去掉末尾0然后转成pem格式并给出n和e

```python
from Cryptodome.PublicKey import RSA
import base64

hex_key = "30819f300d06092a864886f70d010101050003818d00308189028181009cf1af3bffe8855bc30f10c1994ece58002e1795e76710f8b8a023006e1a6068943a4b5a6970d4a4f9ce942d29f3f032fb864a5b0389b6cd40de94ad67f13ea52221a2f94a1112b22bf4d4ca928f404b0b751a0a9c3d893062be8b31a90383b23a626b2c48bd2e5f80c0e7de7d6d5da81c53580a5730cf6b789e344b6284af6d0203010001"
der_data = bytes.fromhex(hex_key)
rsa_key = RSA.import_key(der_data)
n = rsa_key.n
e = rsa_key.e
pem_key = rsa_key.export_key().decode()

print("PEM 格式公钥：\n", pem_key)
print("n =", n)
print("e =", e)
```

得到：

```vbnet
PEM 格式公钥：
 -----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCc8a87/+iFW8MPEMGZTs5YAC4X
lednEPi4oCMAbhpgaJQ6S1ppcNSk+c6ULSnz8DL7hkpbA4m2zUDelK1n8T6lIiGi
+UoRErIr9NTKko9ASwt1GgqcPYkwYr6LMakDg7I6YmssSL0uX4DA5959bV2oHFNY
Clcwz2t4njRLYoSvbQIDAQAB
-----END PUBLIC KEY-----
n = 110209881007357893823335805800713195851127501725957565233140927957700204009298219831317940655870344979959172203765131703915110847527123581538957802617902884782216119145118127834057251159376653146542095451104320803312070357977411524497260098391204298785177487587770308799475139763729699721645361283357313642349
e = 65537

进程已结束，退出代码为 0
```

yafu分解n（这个过程时间有时很快，有时很慢，要几个小时）：（从这里开始，题目就不是上面的内容了，因为我做的题目要几个小时，没跑出来，直接用的其他博客的内容，但过程是一样的）

yafu下载地址：[https://sourceforge.net/projects/yafu/](https://sourceforge.net/projects/yafu/)

```sh
PS E:\我的工具包\yafu-1.34> ./yafu-x64.exe "factor(57840457943390562151183056895981922848981888713417943532946260250633760347281370187050725047626507035739078370095883411759062129893337622945780596526859424702568086671495882125464325172299346781795855931036288858784790023273356190549125683636953077021666004867856782395818167722491980517593426129106599564467)"

fac: factoring 57840457943390562151183056895981922848981888713417943532946260250633760347281370187050725047626507035739078370095883411759062129893337622945780596526859424702568086671495882125464325172299346781795855931036288858784790023273356190549125683636953077021666004867856782395818167722491980517593426129106599564467
fac: using pretesting plan: normal
fac: no tune info: using qs/gnfs crossover of 95 digits
div: primes less than 10000
fmt: 1000000 iterations
Total factoring time = 0.3899 seconds

***factors found***

P154 = 7605291443685150594150190909345113655196508809219162555499789316232908573154196070425269090153291952292016936024761413150455793038505322748933150548026527
P154 = 7605291443685150594150190909345113655196508809219162555499789316232908573154196070425269090153291952292016936024761413150455793038505322748933150548026221

ans = 1
```

得到p和q就能求私钥

```python
from Cryptodome.PublicKey import RSA
from Cryptodome.Util.number import inverse

p = 7605291443685150594150190909345113655196508809219162555499789316232908573154196070425269090153291952292016936024761413150455793038505322748933150548026527
q = 7605291443685150594150190909345113655196508809219162555499789316232908573154196070425269090153291952292016936024761413150455793038505322748933150548026221
e = 65537 

n = p * q
phi_n = (p - 1) * (q - 1)

d = inverse(e, phi_n)
key = RSA.construct((n, e, d, p, q))

private_pem = key.export_key().decode()

print("RSA私钥(PEM)：\n", private_pem)
```

```sh
-----BEGIN RSA PRIVATE KEY-----
MIICWgIBAAKBgFJeF4Hy8C0TKngYptJput2/OTUsjSApDsIpT75Nd+ZUnvR2bYsO
FiAACt+9ev+ZzXLwViPrDe8gImXPYx3YlazV6YHahCTAOilYlcgZSjFkHy7s1ahx
XKic2/lDPF1DdTh2dmbDvbD4YpVVN1tXT+QIqUroL5KWAIXUFjdPFlSzAgMBAAEC
gYApWVrrvY2c0zZKu/VjQ/ivQUPy0b63GmVyS1Lg8frzAiAaESnE2Pl6bwsGbxTE
I+3jeYuE1IdWOAeMnKPhY80fOSgws6vSri7CcxnMUEEn3AMw4YSwBIaBGkdLnfxf
pbS/kUUb/z7/A1SRtNq1n4hZYinnG2NpUuiO1WqwHqOGoQJBAJE14+VVt8ONGIZ1
qIf4cqAnAmtonPhyDNdYZQC0IlxNzyixo/lnlTc80b3jYUA4w8GGQQZea70op4RS
fIJV5J8CQQCRNePlVbfDjRiGdaiH+HKgJwJraJz4cgzXWGUAtCJcTc8osaP5Z5U3
PNG942FAOMPBhkEGXmu9KKeEUnyCVeNtAkAhlDeuCcNj6hXYyg592tsO49ZwZhGe
dik4Bw3cOsuTUr7r5yBHBUgBLQRHh/QuOLIz50rUITOC24rZU4XNUfV7AkB6vJQu
Ke+zaDVMoXKbyxIH8DEJXFkhXjUgZ+SnXZqVbmclPFEe48Cp+cxGtkRjJhfAIZwg
p/pk3lIJdDctay9ZAkBukZv1vD/LR3Y64R5xkoLIliyCTtHgUCY44xkJvQfCGchn
xSu0tBnGgSI3El1K1eOyT6NKSZGeQUGlLGcsBtcT
-----END RSA PRIVATE KEY-----
```

转换为hex：

![image-20250727185958770](b6bfc7cc07251188958e654c5d7af0c6.webp)

```sh
python cs-decrypt-metadata.py -p 私钥 密文
```

![image](664b7d2775e35043bbf51d6a450ad5b1.webp)

有受害机器的主机名，用户名，样本名,其中需要注意的是

```sh
Raw key:  28ab951fc96bcb93ec13cf9dd5f21373
aeskey:  9fe14473479a283821241e2af78017e8
hmackey: 1e3d54f1b9f0e106773a59b7c379a89d
```

有了aeskey就可以加密流量包中的报文  
![image](78369bb42ac7b1b630ed40cbc0ab1b60.webp)  
这种心跳包post为空的流是cs没有给受害机器发送指令  
![image](137337ba14f8b220e74709a855de32fd.webp)  
这种就是发送了指令的心跳包  
![image](d17830930f04287968c175ca42b4ff27.webp)  
对这几个包依次解密，从1382个HTTP流找到上传文件的任务

使用Raw key解密流量

```sh
root@kali2 [~/cs] ➜  python cs-parse-traffic.py -r   a4553adf7a841e1dcf708afc912275ee cs流量分析.pcapng > a.log
```

用cs-parse-http-traffic.py貌似有点问题，原因是响应的报文会比下发任务的报文多4个字节，这里引用官方wp给的脚本  
解密  
![image](5d1811588bd9dcf86bf221750f0060e6.webp)

```python
import hmac
import binascii
import base64
import hexdump
from Crypto.Cipher import AES

AES_KEY = binascii.unhexlify("9fe14473479a283821241e2af78017e8")
HMAC_KEY = binascii.unhexlify("1e3d54f1b9f0e106773a59b7c379a89d")
encrypt_data = "hex"

def decrypt(encrypted_data, iv_bytes, signature, AES_KEY, hmac_key):
    cipher = AES.new(AES_KEY, AES.MODE_CBC, iv_bytes)
    return cipher.decrypt(encrypted_data)

encrypt_data = bytes.fromhex(encrypt_data)
try:
       encrypt_data_l = encrypt_data[4:]
       data1 = encrypt_data_l[:-16]
       signature = encrypt_data_l[-16:]
       iv_bytes = b"abcdefghijklmnop"
       dec = decrypt(data1, iv_bytes, signature, AES_KEY, HMAC_KEY)
except:
       dec = decrypt(encrypt_data, iv_bytes, signature, AES_KEY, HMAC_KEY)

print("counter: {}".format(int.from_bytes(dec[:4], byteorder='big', signed=False)))
print("任务返回长度: {}".format(int.from_bytes(dec[4:8], byteorder='big', signed=False)))
print("任务输出类型: {}".format(int.from_bytes(dec[8:12], byteorder='big', signed=False)))
print(hexdump.hexdump(dec[:1000]))
open('secret.pcapng','wb').write(dec[64:-76])
```

### 2.有.cobaltstrike.beacon\_keys

```python
import base64
import javaobj.v2 as javaobj

with open(".cobaltstrike.beacon_keys", "rb") as fd:
    pobj = javaobj.load(fd)

def format_key(key_data, key_type):
    key_data = bytes(map(lambda x: x & 0xFF, key_data))
    formatted_key = f"-----BEGIN {key_type} KEY-----\n"
    formatted_key += base64.encodebytes(key_data).decode()
    formatted_key += f"-----END {key_type} KEY-----"
    return formatted_key

privateKey = format_key(pobj.array.value.privateKey.encoded.data, "PRIVATE")
publicKey = format_key(pobj.array.value.publicKey.encoded.data, "PUBLIC")

print(privateKey)
print(publicKey)
```

```sh
PS E:\应急响应赛题> python .\getprivatekeys.py
-----BEGIN PRIVATE KEY-----
MIICdgIBADANBgkqhkiG9w0BAQEFAASCAmAwggJcAgEAAoGBAJO0EnJxkHuANSxqFba7FwG9AWV6
L7o8ofulbZoT6fHzEhrDqnAkj4YhIX/d/ApITnjr9OW0i7SATqur5TZs9IhrbOKloRPt2FH8Wy+2
KpJQQzVAALuufy9117C3CXoXt8feGVF01LF87hSZrh5S484+7D9wAR2XHQIsCocj3vEdAgMBAAEC
gYBp/uTqGhNcfZIrMGoquzJ0feWdpETR+qcoBvyTgMz3Y79PU7FhTutsjyQSNgSkgGVII9SYb6t+
OkG6st4H48LLbsOm3sSo6KIoILuwIKPP4weXi8EdeFUeb8adwFgXC2XPs9Q0gnv148UDDNVf6UqO
S/ytp3rebDMCQXUJsuOSJQJBAPzIJvVfLlweOqNScH3/iUrkk/rFFXAlC/K4B0PkHsZuoI2B9/aM
VyGDdk4nUGzswLVizA8bfgqdoJ0vRyV12o8CQQCVlXS+qEOAUxiOiVwtosRP5UUw6lIv2+rMxSeX
VVNfitYanH88/n3sr4UDGizlKZAQC18TDlxeRXwKzWgyov+TAkAM+KxfHQJBAeAab2mMXaeK603Y
qXJfLdd+HglpZ3RY1GZyvH+f7DWwZ5GTkxribAe7hxVXlR6TpuEOD9YDyxdrAkAbDlN1gN3kwiL4
9SN1JbG4edHQDTIccfzAWRDWMJrJ90TOv2vMToPcYcr/SqbANIpYPJZPzhMrAgpzsb+dGRp9AkEA
zWFEOBKqLnfIZR4g6AtuIugScM67nU3Kpo6P9jFZsnLrMjhc6RvyfKWrnQkpeNx8GGagTrOKlTXe
XxcjlSvp0g==
-----END PRIVATE KEY-----
-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCTtBJycZB7gDUsahW2uxcBvQFlei+6PKH7pW2a
E+nx8xIaw6pwJI+GISF/3fwKSE546/TltIu0gE6rq+U2bPSIa2zipaET7dhR/FsvtiqSUEM1QAC7
rn8vddewtwl6F7fH3hlRdNSxfO4Uma4eUuPOPuw/cAEdlx0CLAqHI97xHQIDAQAB
-----END PUBLIC KEY-----
```

PEM转为HEX

![image-20250512201027563](0a183e800c6ce1e4a82234c73af05871.webp)

```sh
30820276020100300d06092a864886f70d0101010500048202603082025c0201000281810093b4127271907b80352c6a15b6bb1701bd01657a2fba3ca1fba56d9a13e9f1f3121ac3aa70248f8621217fddfc0a484e78ebf4e5b48bb4804eababe5366cf4886b6ce2a5a113edd851fc5b2fb62a925043354000bbae7f2f75d7b0b7097a17b7c7de195174d4b17cee1499ae1e52e3ce3eec3f70011d971d022c0a8723def11d020301000102818069fee4ea1a135c7d922b306a2abb32747de59da444d1faa72806fc9380ccf763bf4f53b1614eeb6c8f24123604a480654823d4986fab7e3a41bab2de07e3c2cb6ec3a6dec4a8e8a22820bbb020a3cfe307978bc11d78551e6fc69dc058170b65cfb3d434827bf5e3c5030cd55fe94a8e4bfcada77ade6c3302417509b2e39225024100fcc826f55f2e5c1e3aa352707dff894ae493fac51570250bf2b80743e41ec66ea08d81f7f68c572183764e27506cecc0b562cc0f1b7e0a9da09d2f472575da8f024100959574bea8438053188e895c2da2c44fe54530ea522fdbeaccc5279755535f8ad61a9c7f3cfe7decaf85031a2ce52990100b5f130e5c5e457c0acd6832a2ff9302400cf8ac5f1d024101e01a6f698c5da78aeb4dd8a9725f2dd77e1e0969677458d46672bc7f9fec35b0679193931ae26c07bb871557951e93a6e10e0fd603cb176b02401b0e537580dde4c222f8f5237525b1b879d1d00d321c71fcc05910d6309ac9f744cebf6bcc4e83dc61caff4aa6c0348a583c964fce132b020a73b1bf9d191a7d024100cd61443812aa2e77c8651e20e80b6e22e81270cebb9d4dcaa68e8ff63159b272eb32385ce91bf27ca5ab9d092978dc7c1866a04eb38a9535de5f1723952be9d2
```

使用`cs-decrypt-metadata.py`解密cookie

```sh
PS E:\CTF\MISC\cs解密\cs-decrypt-metadata_V0_0_1> python .\cs-decrypt-metadata.py -p 30820276020100300d06092a864886f70d0101010500048202603082025c0201000281810093b4127271907b80352c6a15b6bb1701bd01657a2fba3ca1fba56d9a13e9f1f3121ac3aa70248f8621217fddfc0a484e78ebf4e5b48bb4804eababe5366cf4886b6ce2a5a113edd851fc5b2fb62a925043354000bbae7f2f75d7b0b7097a17b7c7de195174d4b17cee1499ae1e52e3ce3eec3f70011d971d022c0a8723def11d020301000102818069fee4ea1a135c7d922b306a2abb32747de59da444d1faa72806fc9380ccf763bf4f53b1614eeb6c8f24123604a480654823d4986fab7e3a41bab2de07e3c2cb6ec3a6dec4a8e8a22820bbb020a3cfe307978bc11d78551e6fc69dc058170b65cfb3d434827bf5e3c5030cd55fe94a8e4bfcada77ade6c3302417509b2e39225024100fcc826f55f2e5c1e3aa352707dff894ae493fac51570250bf2b80743e41ec66ea08d81f7f68c572183764e27506cecc0b562cc0f1b7e0a9da09d2f472575da8f024100959574bea8438053188e895c2da2c44fe54530ea522fdbeaccc5279755535f8ad61a9c7f3cfe7decaf85031a2ce52990100b5f130e5c5e457c0acd6832a2ff9302400cf8ac5f1d024101e01a6f698c5da78aeb4dd8a9725f2dd77e1e0969677458d46672bc7f9fec35b0679193931ae26c07bb871557951e93a6e10e0fd603cb176b02401b0e537580dde4c222f8f5237525b1b879d1d00d321c71fcc05910d6309ac9f744cebf6bcc4e83dc61caff4aa6c0348a583c964fce132b020a73b1bf9d191a7d024100cd61443812aa2e77c8651e20e80b6e22e81270cebb9d4dcaa68e8ff63159b272eb32385ce91bf27ca5ab9d092978dc7c1866a04eb38a9535de5f1723952be9d2 IyltNSnpj6lSGi0WGIaJIsFWg6Ko6V+20xExzajz0A3AkRi2MMWjLSZvHltXLFJg5joFEKQ8lQYKh96XCYfDMO3yWWCzyZdpoCLdWRNzR8FN3Z3buww8afGOhKe+NVEWFzTPafNZh3kFlWUf5zk/etCn8WPy4qg4BArMvbx/yqM=
Encrypted metadata: IyltNSnpj6lSGi0WGIaJIsFWg6Ko6V+20xExzajz0A3AkRi2MMWjLSZvHltXLFJg5joFEKQ8lQYKh96XCYfDMO3yWWCzyZdpoCLdWRNzR8FN3Z3buww8afGOhKe+NVEWFzTPafNZh3kFlWUf5zk/etCn8WPy4qg4BArMvbx/yqM=
Decrypted:
Header: 0000beef
Datasize: 0000005d
Raw key:  a4553adf7a841e1dcf708afc912275ee
 aeskey:  a368237121ef51b094068a2e92304d46
 hmackey: b6315feb217bd87188d06870dd92855b
charset: 03a8 ANSI/OEM Simplified Chinese (PRC, Singapore); Chinese Simplified (GB2312)
charset_oem: 03a8 ANSI/OEM Simplified Chinese (PRC, Singapore); Chinese Simplified (GB2312)
bid: 5f96edca 1603726794
pid: 0acc 2764
port: 0
flags: 0e
var1: 6
var2: 2
var3: 9200
var4: 32760
var5: 265866928
var6: 265854304
var7: 2507253952
Field: bytearray(b'WIN-8FC6TKPDPOR')
Field: bytearray(b'Administrator')
Field: bytearray(b'artifact.exe')
```

```sh
Raw key:  a4553adf7a841e1dcf708afc912275ee
aeskey:  a368237121ef51b094068a2e92304d46
hmackey: b6315feb217bd87188d06870dd92855b
```

使用Raw key解密流量

```sh
root@kali2 [~/cs] ➜  python cs-parse-traffic.py -r   a4553adf7a841e1dcf708afc912275ee cs流量分析.pcapng > a.log
```

![image-20250512202352621](eb989c8321a609a4425bec4aec200c6e.webp)

最后可以看其他的文章：

[https://forum.butian.net/share/1861](https://forum.butian.net/share/1861)  
(Cobaltstrike4.0 学习——http分阶段stagebeacon上线流量刨根问底）

[https://ta0.fun/posts/a70a62d9/](https://ta0.fun/posts/a70a62d9/)  
(CobaltStrike4.0流量分析）

冷鸢 网络安全

\_\_EOF\_\_
