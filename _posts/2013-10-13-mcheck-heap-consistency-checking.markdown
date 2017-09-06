---
layout: post
title: "使用 mcheck 检测堆(Heap)一致性"
date: 2013-10-13 12:50
categories: 编程 C/C++
---

堆被破坏通常很难检测到，除非发生很明显的违规操作，比如多次释放，释放不正确的
内存块等。堆不仅包含分配给应用程序的内存块，还包含了堆管理器维护的已分配或者未分配
的内存块的信息，如果这些信息无意的被修改，会导致程序异常崩溃，而且很难检测，因为
它通常还带有随机性。例如超出内存块的边界进行写操作等，这在使用原始指针操作内存块
时很容易出现的问题。C++ 提供 **std::vector<>** 在堆中创建数组，C++ 11 提供
**std::array<T>** 操作栈上的数组，比提供带有校验功能的接口对数组进行操作，这大大
降低了堆栈被破坏的概率，应该习惯去使用它们。

mcheck 是 glibc 提供的检测内存一致性的工具，有两种使用方式。
1. 在代码中调用 mcheck(...)。这个函数的原型在 **mcheck.h** 头文件中。mcheck必须在
任何 **malloc** 类的分配函数之前调用，否则返回失败。
2. 在程序链接时添加 -lmcheck 选项，这样不用修改代码也能够正常使用，甚是方便。

但 mcheck 无法检测到超出内存块边界进行读写的操作。

<!-- more -->

```c++

#include <stdlib.h>
#include <mcheck.h>

#include <iostream>
#include <memory>
#include <vector>



int main(int argc, char *argv[])
{
  (void)argc;
  (void)argv;


  char *leak_m = (char*)::malloc(128);
  leak_m[128] = 0;
  leak_m[129] = 0;
  (void)leak_m;

  void *leak_cm = ::calloc(256, 1);
  (void)leak_cm;
  free(leak_cm);
  free(leak_cm);

  return 0;
}
```

```shell
$ g++ -g -O0 -o heapC heap-corruption.cc -lmcheck
$ MALLOC_CHECK_=2 ./heapC
block freed twice
Aborted
```

MALLOC_CHECK_ 环境变量控制如何检测堆破坏的情况。0：所有检测到的情况都被忽略;
1:将检测到的错误信息打印到 stderr; 2: 如果检测到被破坏则调用 abort() 终止程序。
可以设置为3,表示同时执行 1 和 2 的动作。


-----

## 参考链接 ##
1. [3.2.2.9 Heap Consistency Checking](http://www.gnu.org/software/libc/manual/html_node/Heap-Consistency-Checking.html)
2. [Diagnosing Memory Heap Corruption in glibc with MALLOC_CHECK_](http://www.novell.com/support/kb/doc.php?id=3113982)
3. [Heap Corruption](http://www.efnetcpp.org/wiki/Heap_Corruption)
