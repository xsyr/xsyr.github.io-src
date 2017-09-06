---
layout: post
title: "使用 mtrace 简单的进行内存泄漏检测"
date: 2013-10-12 22:18
categories: 编程 C/C++
---

常在河边走，哪能不湿鞋。C 和 C++ 都需要手动管理指针，一不小心就忘记释放而泄漏了。
可以使用 mtrace 简单的进行内存泄漏检测，它 hook malloc(), realloc(), memalign(),
calloc() 和 free() ，对分配和释放内存的操作进行配对检测，如果发现有内存泄漏的情况，
会记录导致内存泄漏的分配函数调用所在的位置，并将记录保存到环境变量 MALLOC_TRACE
指定的文件中，然后就可以使用 mtrace 命令来查看日志了。

```shell
$ mtrace path/to/your/app path/to/your/log-file
```

-----

## 用法 ##

1. 引用头文件 **#include <mcheck.h>**
2. 在开始跟踪内存分配的地方调用 **mtrace(void)**
3. 在结束跟踪的地方调用 **muntrace(void)**
4. 编译程序并将日志文件的路径写到 MALLOC_TRACE 环境变量中. Note: 因为后面用
**mtrace** 分析日志文件时会用到程序的 符号信息，所以在编译是需要添加 **-g -O0**
的编译选项。

```shell
$ MALLOC_TRACE=path/to/your/log-file  path/to/your/app
```

启用 **mtrace(void)** 会影响程序的性能，所以这种方法只是用来调试程序，正式发布时
必须要移除这些代码。



```c++
#include <stdlib.h>
#include <mcheck.h>

#include <iostream>
#include <memory>
#include <vector>


struct GlobalAlloc {
  void *p;
  GlobalAlloc() {
    mtrace();
    p = malloc(1024);
  }

  ~GlobalAlloc() {
    free(p);
    ::muntrace();
  }
};

GlobalAlloc g;

int main(int argc, char *argv[])
{
  (void)argc;
  (void)argv;


  char *array = new char[4096];
  (void)array;

  void *leak_m = ::malloc(128);

  (void)leak_m;

  void *leak_cm = ::calloc(256, 1);
  (void)leak_cm;

  getchar();

  return 0;
}

```

```shell
$ g++ -std=c++11 -g -O0 -o app main.cc
$ MALLOC_TRACE=test-mtrace.dat ./app
```

-----

## 分析日志文件 ##

```shell
$ mtrace ./app test-mtrace.dat

Memory not freed:
-----------------
           Address     Size     Caller
0x0000000001e6e870   0x1000  at 0x7f568df55ebd
0x0000000001e6f880     0x80  at /home/xinsuiyuer/cppprojects/demo/main.cc:34
0x0000000001e6f910    0x100  at /home/xinsuiyuer/cppprojects/demo/main.cc:38
```

第二和第三个结果很容易就看懂，但是第一个结果即使已经在编译的时候生成了调试符号，
但却没有正确的显示源码的调用位置(line: 30)。这是因为 line 30 的代码并没有直接调用
malloc这类函数，而是通过 **new** 操作符简介调用的, 这个间接调用 malloc 的位置
在 libstdc++.so 共享文件中，可以对比一下进程的内存映射就可以知道 0x7f568df55ebd
这个位置位于 libstdc++.so 中。

![mem-leak-detect-by-mtrace-mmap]( /assets/img/mem-leak-detect-by-mtrace-mmap.png)



真是由于这样的原因，mtrace并不适合用来检测 C++ 程序的内存泄漏，因为它无法给出
这个正确的调用位置。

------


## 参考引用 ##

1. [How to install the tracing functionality](http://www.gnu.org/software/libc/manual/html_node/Tracing-malloc.html)
