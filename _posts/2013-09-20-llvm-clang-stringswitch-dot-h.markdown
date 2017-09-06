---
layout: post
title: "LLVM - StringSwitch.h"
date: 2013-09-20 22:41
categories: 编程
---

偶然间发现这个 **StringSwitch** 类( 位于 llvm 项目的 lib/ADT/StringSwitch.h )，
感觉特新颖，而且它的实现用到了模板类的一下高级特性。不得不感叹 C++ 语法的自由与复杂。
使用这个类可以避免一大串的 if - else if 语句，也弥补了 switch 语法的不足，
它实现了 switch - return 的语法。在这样的场景里使用
**状态模式** 显得大财小用，如果使用它则能让代码看起来更优雅。它的用法如下：

1. 比较字符串并返回字符串
```c++
return llvm::StringSwitch<const char *>(Value)
  .Cases("arm9e", "arm946e-s", "arm966e-s", "arm968e-s", "arm926ej-s","armv5")
  .Cases("arm10e", "arm10tdmi", "armv5")
  .Cases("arm1020t", "arm1020e", "arm1022e", "arm1026ej-s", "armv5")
  .Case("xscale", "xscale")
  .Cases("arm1136j-s", "arm1136jf-s", "arm1176jz-s", "arm1176jzf-s", "armv6")
  .Case("cortex-m0", "armv6m")
  .Cases("cortex-a8", "cortex-r4", "cortex-a9", "cortex-a15", "armv7")
  .Case("cortex-a9-mp", "armv7f")
  .Case("cortex-m3", "armv7m")
  .Case("cortex-m4", "armv7em")
  .Case("swift", "armv7s")
  .Default(0);
```

2. 比较字符串并返回某种类型的值（如：枚举成员）
```c++
Color color = StringSwitch<Color>(argv[i])
  .Case("red", Red)
  .Case("orange", Orange)
  .Case("yellow", Yellow)
  .Case("green", Green)
  .Case("blue", Blue)
  .Case("indigo", Indigo)
  .Cases("violet", "purple", Violet)
  .Default(UnknownColor);
```


## 实现这个类的关键 ##

1. StringSwitch 构造函数的参数，它等价于 switch 语句的表达式。

1. Case, StringSwitch 等方法的参数：**const char (&S)[N]**   
   这个参数比较难看懂，用到了 模板的 trick，它的语义如下：
   **S** 是一个引用，指向长度为 **N** 的 const 数组，这个数组的元素类型为 **char**。
   **N** 的值在编译期就可以计算出来。    
   如果传递的过来的是字符串，**N** 的值为 strlen(S) + 1。
   **+1** 是因为它的长度包括字符串末尾的 null 结束符。     
   如果是 const int (&S)[N]，则 **N** 就是实际数组的长度。

2. 实现 switch 的 **default** 关键字：**R Default(const T& Value) const**    
   返回值类型为 R，默认与 T 的参数类型相同。

3. 返回值类型转换函数：**operator R() const**     
   这个很重要，缺少了这个函数就不优雅了。


llvm-StringSwitch.h
