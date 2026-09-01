---
title: "APK 分析"
type: technique
category: "应用分析"
competition: ""
year: ""
stage: ""
mode: ""
tags: [APK分析, JADX, blutter, Frida, 手机取证, 加解密]
images: 0
status: "完整"
source: "原创"
created: 0000-00-00
updated: 2026-09-01
summary: "APK/Flutter 逆向技巧集：blutter 分析 Flutter 应用、jadx 反编译、Frida 动态调用/改返回值，及按 Dex 头判断安卓版本"
---
# APK 分析

## Flutter应用逆向

用blutter来跑，安装在wsl里面了

## 解决MuMu模拟器连不上adb

```
adb connect 127.0.0.1:5555
//具体端口查看设置
```

## Jadx显示所有代码

```
jadx_gui.exe --show-bad-code *.apk
```

## AndroidManifest.xml

`android:minSdkVersion`：支持的最低安卓版本

## 主入口

`MainActivity`

起始函数（生命周期）：`onCreate`

## Frida常用操作

1、字符串判断等使用的`iseqauls`方法可以直接使用弘连内置方法

AES等加密也可以使用内置方法

可以使用弘连的自定义方法修改某个函数的返回值

2、调用没有被使用的函数

例子：

```java
public class FridaActivity2 extends BaseFridaActivity {
    private static boolean static_bool_var = false;
    private boolean bool_var = false;

    @Override

    private static void setStatic_bool_var() {
        static_bool_var = true;
    }

    private void setBool_var() {
        this.bool_var = true;
    }

    @Override
    public void onCheck() {
        if (static_bool_var && this.bool_var) {
            CheckSuccess();
            return;
        }
        super.CheckFailed();
    }
}
```

脚本：

```javascript
Java.perform(function () {
    Java.use("com.example.androiddemo.Activity.FridaActivity2").setStatic_bool_var();

    Java.choose("com.example.androiddemo.Activity.FridaActivity2", {
        onMatch:function(instance){
            instance.setBool_var();
        }, onComplete:function(){}
    })
});
```

3、修改变量的值（下划线是为了区分同名方法）

例子：

```java
public class FridaActivity3 extends BaseFridaActivity {
    private static boolean static_bool_var = false;
    private boolean bool_var = false;
    private boolean same_name_bool_var = false;

    @Override

    private void same_name_bool_var() {
        Log.d("Frida", static_bool_var + " " + this.bool_var + " " + this.same_name_bool_var);
    }

    @Override
    public void onCheck() {
        if (static_bool_var && this.bool_var && this.same_name_bool_var) {
            CheckSuccess();
            return;
        }
        super.CheckFailed();
    }
}
```

脚本：

```javascript
Java.perform(function(){
    Java.use("com.example.androiddemo.Activity.FridaActivity3").static_bool_var.value = true;
    Java.choose("com.example.androiddemo.Activity.FridaActivity3", {
        onMatch:function(instance){
            instance.bool_var.value = true;
            instance._same_name_bool_var.value = true;
        },
        onComplete:function(){}
    })
})
```

4、加载Class并修改返回值

```javascript
Java.perform(function(){

    Java.enumerateClassLoaders({
        onMatch:function(loader){
            try{
                if(loader.findClass("com.example.androiddemo.Dynamic.DynamicCheck")){
                    Java.classFactory.loader = loader;
                }
            }catch(error){
                console.log("found error:"+error);
            }
        },onComplete:function(){}
    })
    Java.use("com.example.androiddemo.Dynamic.DynamicCheck").check.implementation = function(){return true;};

})
```

5、修改函数返回值

```javascript
Java.perform(function(){
    Java.use("com.example.androiddemo.Activity.Frida6").check.implementation = function(){return true};
})
```

6、直接调用某个方法并传入参数

```javascript
Java.perform(function (){
    let decrypt=Java.use("org.sugram.foundation.cryptography.IsaacCipher").decrypt("E59……","MTAxMzg1MA==");
    console.log("decrypt:",decrypt);
});
```

7、调用某个没有被初始化的方法并传入参数

```javascript
Java.perform(function (){
    let decrypt=Java.use("x.NativeGuard").$new().enc1ypt("78F459A");
    console.log("decrypt:",decrypt);
});
```

***

# 通过Dex文件判断安卓版本方法

要判断Dex文件支持的Android版本，主要通过分析Dex文件头中的**版本标识符（Version String）** 来实现。以下是具体步骤和原理：

---

### **1. Dex文件头结构**

Dex文件的前8个字节是**魔数（Magic Number）**，格式为：  
`64 65 78 0A` (`dex\n`) + `版本标识符（3字节）` + `00`（结束符）。  
示例：  
`64 65 78 0A 30 33 39 00` → 版本字符串为 `"039"`。

---

### **2. 版本标识符与Android版本的对应关系**

|Dex版本|Android版本|API级别|特性说明|
|--|--|--|--|
|**035**|≤ 4.0.4 (Ice Cream Sandwich)|≤ 15|早期Dalvik虚拟机格式|
|**036**|4.1–4.4 (Jelly Bean)|16–19|优化字节码布局|
|**037**|5.0–6.0 (Lollipop–Marshmallow)|21–23|支持ART，新增指令|
|**038**|7.0–8.1 (Nougat–Oreo)|24–27|支持动态调试信息|
|**039**|9.0–10.0 (Pie–Android 10)|28–29|默认启用R8优化，扩展类型支持|
|**040**|11.0 (Android 11+)|≥ 30|隐藏API限制，新压缩格式|
|**041**|12.0+ (Android 12+)|≥ 31|支持JDK 11特性|

> **注意**：高版本Android通常兼容低版本Dex格式，但反之不成立。

---

### **3. 操作方法**

#### **方法1：十六进制编辑器**

1. 用工具（如`hexdump`、010 Editor）打开Dex文件。
2. 查看第5–7字节（偏移量`0x04–0x06`）：
   ```
   00000000: 64 65 78 0A 30 33 39 00  → 版本 "039" (Android 9+)
   ```

#### **方法2：命令行工具**

```sh
# Linux/macOS
hexdump -C classes.dex | head -n1
# 输出示例：00000000  64 65 78 0a 30 33 39 00  ... → 版本039

# Windows (使用PowerShell)
Format-Hex -Path classes.dex -Count 8
```

#### **方法3：Python脚本**

```python
def get_dex_version(dex_file):
    with open(dex_file, 'rb') as f:
        magic = f.read(8)
        if magic[0:4] != b'dex\n':
            return "无效Dex文件"
        version = magic[4:7].decode('ascii')
        return version

print(get_dex_version("classes.dex"))  # 输出示例：039
```

---

### **4. 注意事项**

- **多Dex文件**：APK可能包含多个Dex（如`classes.dex`, `classes2.dex`），需逐一检查。
- **版本兼容性**：
  - 编译时指定`targetSdkVersion`决定Dex版本。
  - Android 5.0+ (API 21+) 使用ART，支持`037+`；低于此版本需用`035/036`。
- **混淆影响**：ProGuard/R8优化可能改变Dex结构，但不影响版本标识符。

---

### **5. 版本标识符的生成规则**

Dex版本由构建工具（如D8/R8）根据以下规则生成：

```gradle
// build.gradle
android {
    compileSdkVersion 31
    defaultConfig {
        targetSdkVersion 30  // 生成040版本Dex
    }
}
```

- `targetSdkVersion 30` → Dex版本 **040** (Android 11+)
- `targetSdkVersion 29` → Dex版本 **039** (Android 9+)

---

### **总结**

通过解析Dex文件头的**第5–7字节**，获取版本标识符（如`038`），即可快速判断其最低支持的Android版本。实际兼容性需结合`minSdkVersion`综合评估。
