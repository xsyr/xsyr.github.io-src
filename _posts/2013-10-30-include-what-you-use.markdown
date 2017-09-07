---
layout: post
title: "使用 I.W.Y.U 整理头文件引用"
date: 2013-10-30 20:43
comments: true
categories: 编程 C/C++
---

C++ 的复杂性导致其编译速度极慢，特别是项目的代码量很大时尤为明显。通常为了提高
编译速度往往是无所不用其极，pimpl，预编译，ccache，distcc分布式编译，尽量使用前置声明，去掉多余的
头文件引用等。代码经过重构之后，很多头文件就不再需要引用了，但是当源文件引用很多的头文件时，
就比较难确定哪些头文件不再需要。如果不清理，会减慢编译速度和增大二进制文件的大小，
当头文件中包含模板时尤为明显。一个方法是先去掉一个头文件，然后看看能否编译通过，
不断的重复这个过程。但是重构的代码比较多时，这样的方法效率太低。IWYU 就是这样的一个工具，
帮你找出多余的头文件引用。

[IWYU](https://code.google.com/p/include-what-you-use/) 使用 clang 分析符号的引用。
是 google 的一个项目，它可以给出应该引用和移除的头文件，但并不能保证 100% 是正确的，此 wiki [Why Include What You Use Is Difficult](https://code.google.com/p/include-what-you-use/wiki/WhyIWYUIsDifficult) 描述了其中的难点（当然都是语言特性的原因）。

<!-- more -->

## 安装 ##
安装前必须安装对应版本的 clang 的开发包。
```bash
$ zypper install llvm llvm-devel llvm-clang llvm-clang-devel
```

下载源码，可以下载打包好的 tar [include-what-you-use-3.3.tar.gz](https://docs.google.com/file/d/0ByBfuBCQcURXQktsT3ZjVmZtWkU/edit)
或者从 svn 迁出
```bash
$ svn co http://include-what-you-use.googlecode.com/svn/trunk/ include-what-you-use
```

可以单独的编译，也可以作为 LLVM 的一部分。单独编译比较方便。
```bash
$ mkdir build
$ cd include-what-you-use/build
$ cmake -G "Unix Makefiles" -DLLVM_PATH=/usr../include-what-you-use
$ make
```


## 使用 ##
IWYU 使用很简单，如果有 Makefile，直接
```bash
$ make -B -k CXX=include-what-you-use
```

例子：
```cpp
#include <stdio.h>
#include <malloc.h>
#include <limits.h>

int foo(void) {
  fprintf(stderr, "an error\n");
  return INT_MAX;
}
```

```bash
$ include-what-you-use bar.cc

bar.cc should add these lines:

bar.cc should remove these lines:
- #include <malloc.h>  // lines 2-2

The full include-list for bar.cc
#include <limits.h> // for INT_MAX
#include <stdio.h> // for fprintf, stderr
---
```

有时候相同的符号在很多文件中都是定义，可以使用 map 的方法指定引用哪个文件。map 文件
的方法可以参考文档 [IWYUMappings](https://code.google.com/p/include-what-you-use/wiki/IWYUMappings)。
然后在运行 IWYU 时指定 map 文件：
```bash
$ make -B -k CXX=include-what-you-use CFLAGS=" -Xiwyu --mapping_file=mapfile"
```

有时候 IWYU 也会犯错，它会错误的认为可以删除某些头文件的引用。这种情况下可以使用 IWYU
 pragmas 控制 IWYU 的行为。参考 [IWYU pragmas](https://code.google.com/p/include-what-you-use/wiki/IWYUPragmas)。


可以将 IWYU 保存到文件中，之后使用其附带的 fix_includes.py 自动对代码进行修复。
但应该慎重....    
```bash
$ make -B -k CXX=include-what-you-use > iwyu.out
$ fix_includes.py < iwyu.out
```



IWYU 没有那么容易使用，但项目代码量大的时候值得一试。
IWYU 当前还未支持 'forward-declared'，期待中！

## 参考链接 ##
1. [include-what-you-use](https://code.google.com/p/include-what-you-use/)
2. [Using include-what-you-use](http://blog.mozilla.org/nnethercote/2013/08/13/using-include-what-you-use/)
