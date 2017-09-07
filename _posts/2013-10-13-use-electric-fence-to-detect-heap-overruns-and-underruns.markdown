---
layout: post
title: "使用 Electric Fence 检测内存越界操作"
date: 2013-10-13 18:07
comments: true
categories: 编程 C/C++
---

此文《[使用 mcheck 检测堆(Heap)一致性](http://xinsuiyuer.github.io/blog/2013/10/12/mtrace-usage/)》
介绍用 mcheck 检测内存的一致性，但它无法检测越过内存块上下边界进行读写之类的违规
操作。它只能在违规操作导致堆管理器维护的内存块信息被破坏之后才能检测出来，而且
即使能检测出来，也无法精确的定位违规操作代码所在的位置。Electric Fence 能够完美的
完成这种检测。但它也有和 mcheck 一样的不足，无法正确定位 C++ 中 new, new[], delete,
delete[] 的问题，因为它只 hook C 语言的那些内存操作函数。Electric Fence 也无法检测
内存泄漏。

## Electric Fence 简介 ##
Electric Fence 能够检测到使用 malloc() 系列函数分配的内存块被越界读写的操作，
它还能检测到对使用 free() 释放之后的内存块进行读写的操作。Note：读和写操作都可以
被检测到，然后精确定位违规操作的代码所在的位置，这要求在编译程序时必须保留调试符号
信息(指定 **-g -O0** )，否则无法定位代码所在的文件和行数。


## Electric Fence 原理 ##
Electric Fence 使用虚拟内存技术，在 malloc() 分配到的内存块的前后分别放置一个
不能访问的内存页，当应用程序去读写这两个内存页时硬件会引发段错误，OS就终止应用
程序。这时候我们就可以使用调试器（如 gdb）捕获段错误的信号，它结合调试符号信息
就可以定问到内存违规操作的代码所在的位置。 Electric Fence 安装很简单，在 openSUSE上
直接执行    
```bash
$ zypper install ElectricFence
$ rpm -ql ElectricFence
/usr/bin/ef
/usr/lib64/libefence.a
/usr/lib64/libefence.so
/usr/lib64/libefence.so.0
/usr/lib64/libefence.so.0.0
/usr/share/doc/packages/ElectricFence
/usr/share/doc/packages/ElectricFence/CHANGES
/usr/share/doc/packages/ElectricFence/COPYING
/usr/share/doc/packages/ElectricFence/README
/usr/share/man/man3/efence.3.gz
```

------

## 使用 ##
只要添加链接选项 **-lefence** 链接 **libefence.so**，它会在程序运行时预先加载
 **libefence.so** Hook 对 malloc(...) 的调用。也可以不用编译程序而通过设置 **PRE_LOAD=/usr/lib64/libefence.so** 环境变量
来实现或者直接链接 **/usr/lib64/libefence.a**。默认情况下 Electric Fence 只会检测
读写越下边界和已释放的内存块的违规操作。Electric Fence 不能与其他 内存检测工具
或者内存分配器使用，因为大家都是通过 hook 内存分配函数来实现内存检测的。

### 1. 越下边界写 ###
```cpp
#include <stdlib.h>
#include <mcheck.h>
#include <iostream>

int main(int argc, char *argv[])
{
  (void)argc;
  (void)argv;


  char *leak_m = (char*)::malloc(2 * sizeof(void*));
  leak_m[2 * sizeof(void*)] = 'a';

  return 0;
}
```

```bash
$ g++ -g -O0 -o heapC heap-corruption.cc -lefence
$ gdb -q ./heapC
(gdb) run
Starting program: /home/xinsuiyuer/cppprojects/demo/heapC

  Electric Fence 2.2.0 Copyright (C) 1987-1999 Bruce Perens <bruce@perens.com>

Program received signal SIGSEGV, Segmentation fault.
0x0000000000400871 in main (argc=1, argv=0x7fffffffdaf8) at heap-corruption.cc:18
18        leak_m[2 * sizeof(void*)] = 'a';
(gdb)
```

### 2. 读写已释放的内存块 ###
```cpp
#include <stdlib.h>
#include <mcheck.h>
#include <iostream>

int main(int argc, char *argv[])
{
  (void)argc;
  (void)argv;


  char *leak_m = (char*)::malloc(2 * sizeof(void*));
  free(leak_m);

  leak_m[0] = 'a';

  return 0;
}
```


```bash
$ g++ -g -O0 -o heapC heap-corruption.cc -lefence
$ gdb -q ./heapC
(gdb) run
Starting program: /home/xinsuiyuer/cppprojects/demo/heapC

  Electric Fence 2.2.0 Copyright (C) 1987-1999 Bruce Perens <bruce@perens.com>

Program received signal SIGSEGV, Segmentation fault.
0x00000000004008c9 in main (argc=1, argv=0x7fffffffdaf8) at heap-corruption.cc:16
16        leak_m[0] = 'a';
(gdb)
```

------

## 高级应用 ##

Electric Fence 提供了 **EF_ALIGNMENT**, **EF_PROTECT_BELOW**, **EF_PROTECT_FREE**,
**EF_ALLOW_MALLOC_0**, **EF_FILL** 五个全局变量（可以在gdb中用命令设置）和
环境变量(可以在程序启动时设置)。

### 1. EF_ALIGNMENT ###
这个变量控制的是分配到的内存块的对齐大小，它是一个整数值，
默认是当前OS的字大小。当申请的内存块不是这个值的整数倍时，会向上取整直到满足对齐要求，
因为内存对其才能让CPU更有效率的工作。可以使用下面的命令查看当前的字大小：
```bash
$ getconf LONG_BIT
64
```

例如我的 OS 是 64bit，字大小就为 64bit = 8Byte。当我申请的内存大小是 9B 时，
malloc(...) 会向上取整到 16B = 2x8B。这样当我访问 array[9] 甚至是 array[15]时
``(char *array)``会是正常的，因为对那部分内存进行访问是合法的，这样就无法检测到内存
越界访问了。这样的行为是程序的错误，当现在在 64bit 的系统上却能够很好的运行，但是
当编译成 32bit 并拿到 32bit 的系统去运行时很有可能会出现问题，因为访问
array[12], array[13], array[14], array[15] 会发生越界。这样会出现在一个平台上能
很好运行，到另一个平台上无法运行的现象。   
因此，需要将 malloc(...) 分配对内存进行严格的对其才能检测到这样现象，这时候设置
EF_ALIGNMENT 就变得很有帮助了，可以根据实际情况设置它的值，如 4, 2, 1。这个值越小
越严格。

```cpp

#include <stdlib.h>
#include <mcheck.h>
#include <iostream>

int main(int argc, char *argv[])
{
  (void)argc;
  (void)argv;

  char *leak_m = (char*)::malloc(2 * sizeof(void*) + 1);
  leak_m[3 * sizeof(void*) + 1] = 'a';

  free(leak_m);

  return 0;
}
```

```bash
$ g++ -g -O0 -o heapC heap-corruption.cc -lefence
$ gdb -q ./heapC
(gdb) run

  Electric Fence 2.2.0 Copyright (C) 1987-1999 Bruce Perens <bruce@perens.com>
[Inferior 1 (process 11193) exited normally]

$ gdb -q ./heapC
(gdb) set environment EF_ALIGNMENT=1
(gdb) run

  Electric Fence 2.2.0 Copyright (C) 1987-1999 Bruce Perens <bruce@perens.com>

Program received signal SIGSEGV, Segmentation fault.
0x00000000004008c1 in main (argc=1, argv=0x7fffffffdae8) at heap-corruption.cc:12
12        leak_m[3 * sizeof(void*) + 1] = 'a';
```

可以看到两次运行的结果不同，第二次通过设置内存块严格对齐之后问题就出现了。

### 2. EF_PROTECT_BELOW ###
EF_PROTECT_BELOW=1 时在 Electric Fence 在内存块的之前也添加一个无法访问的内存页。
当访问越过内存块上边界的位置时会发生违规访问。这类违规操作很容易破坏掉其位置所在的
内存块的内容，并且很隐蔽，可能需要很长时间才能以莫名其妙的现象体现出来。
```cpp

#include <stdlib.h>
#include <mcheck.h>
#include <iostream>

int main(int argc, char *argv[])
{
  (void)argc;
  (void)argv;

  char *leak_m = (char*)::malloc(2 * sizeof(void*) + 1);
  leak_m[-1] = 'a';

  free(leak_m);

  return 0;
}
```

```bash
$ g++ -g -O0 -o heapC heap-corruption.cc -lefence
$ gdb -q ./heapC
(gdb) run

  Electric Fence 2.2.0 Copyright (C) 1987-1999 Bruce Perens <bruce@perens.com>
[Inferior 1 (process 11355) exited normally]

$ gdb -q ./heapC
(gdb) set environment EF_ALIGNMENT=1
(gdb) run

  Electric Fence 2.2.0 Copyright (C) 1987-1999 Bruce Perens <bruce@perens.com>

Program received signal SIGSEGV, Segmentation fault.
0x00000000004008c1 in main (argc=1, argv=0x7fffffffdae8) at heap-corruption.cc:12
12        leak_m[-1] = 'a';
```

### 3. EF_PROTECT_FREE ###
Electric Fence 通常会将释放的内存放到一个内存池中，以后这块内存块可以被 realloc 用来重新分配。
内存池中的内存块虽然已经是释放了，此释放（free 被 Electric Fence hook 之后）
非彼释放（glibc 所实现的 free），这是 Electric Fence 的行为，因为加载 libefence.so 之后它成为
heapC 的一部分，所以这块内存被 Electric Fence 放到内存池之后对与 heapC 来说它仍然是可以使用的，
这可能与 glibc 实现的不同。由于这样的差异可能会导致程序在用 glibc 的接口时出问题了，
然后使用 Electric Fence 检测时却没有出现问题。如果我们怀疑程序中有访问内存池中的
空闲内存块的嫌疑，可以将 EF_PROTECT_FREE 设置为 1 来检测这种情况。

```cpp
#include <stdlib.h>
#include <mcheck.h>
#include <iostream>
#include <unistd.h>
#include <string.h>

int main(int argc, char *argv[])
{
  (void)argc;
  (void)argv;

  int page_size = ::getpagesize();

  std::cout << "page size: " << page_size << std::endl;

  char *large_block = (char *)::malloc(64 * page_size);
  memset(large_block, 64 * page_size, 0xFF);
  std::cout << "block : [ "
      << (void*)large_block
      << ", "
      << (void*)(large_block + 46 * page_size - 1)
      << " ]"
      << std::endl;


  char *first_alloc = (char *)::malloc(page_size - 8);
  memset(first_alloc, page_size - 8, 0xFF);
  std::cout << "First :   " << (void*)first_alloc << std::endl;

  void *dummy = ::malloc(page_size - 8);
  memset(dummy, page_size - 8, 0xFF);
  std::cout << "Dummy :   " << dummy << std::endl;

  free(first_alloc);

  char *second_alloc = (char*)::malloc(page_size/2);
  memset(second_alloc, page_size/2, 0xFF);
  std::cout << "Second :  " << (void*)second_alloc << std::endl;

  first_alloc[0] = 'a';

  second_alloc[page_size/2 - 1] = 'a';

  free(dummy);
  free(second_alloc);

  return 0;
}
```

```bash
$ g++ -g -O0 heap-corruption.cc -o heapC -lefence
$ ./heapC
page size: 4096

  Electric Fence 2.2.0 Copyright (C) 1987-1999 Bruce Perens <bruce@perens.com>
block : [ 0x7fa94421e000, 0x7fa94424bfff ]
First :   0x7fa94425f000
Dummy :   0x7fa944261000
Second :  0x7fa94425f800
```

可以看到 Second 的内存块的首地址落在已释放的 First 内存块的范围内，Electric Fence
用 First 块的内存来重新分配给 Second，它是在内存池中的，所以我们能通过 first_alloc[0]
正常访问它，但逻辑上已经是错误了，因为 First 已经被释放了，如果没有发现这种错误，
那么这种违规操作将会破坏另一个内存块的数据，导致产生很难定位的bug。C 或者 C++ 运行库中
肯定也会使用内存池的技术，所以这种 bug 还是比较常见的。

当将 EF_PROTECT_FREE 设置为 1, 则 Electric Fence 不会将释放的内存重新分配，这样就可以
检测到错误。但这样做有一个问题，如果程序需要分配很多的内存空间，则会导致物理内存
资源耗尽或者进车地址空间被分配殆尽。

```bash
$ gdb -q ./heapC
(gdb) set environment EF_PROTECT_FREE 1
(gdb) run
page size: 4096

  Electric Fence 2.2.0 Copyright (C) 1987-1999 Bruce Perens <bruce@perens.com>
block : [ 0x7ffff7eca000, 0x7ffff7ef7fff ]
First :   0x7ffff7f0b000
Dummy :   0x7ffff7f0d000
Second :  0x7ffff7f0f800

Program received signal SIGSEGV, Segmentation fault.
0x0000000000400da6 in main (argc=1, argv=0x7fffffffdaf8) at heap-corruption.cc:40
40        first_alloc[0] = 'a';
```

可以看到 Second 块分配得到新的地址。而且错误也能检测出来了。


### 4. EF_ALLOW_MALLOC_0 ###
Electric Fence 默认会对 malloc(0) 的参数为 0 的情况也会做检测，因为这明显是一种
程序的错误情况，如果遇到特殊的场景容许这种情况出现，可以将 EF_ALLOW_MALLOC_0
设置为 1 来避免 Electric Fence做这样的检查。

### 5. EF_FILL ###
EF_FILL 的值的范围是 0 - 255, 可以设置指定的值使 Electric Fence 在分配内存之后
将内存块初始化为此值，填充合适的值将会在引发内存违规访问时能够更加容易的发现问题。
比如初始化为0,这样如果有一个指针的位置在这块内存块中，当解指针时就会访问位置为
0x0000000000000000 的位置，这样的指针比野指针更容易定位。MS C++ 编译器在 DEBUG 模式
下会将内存初始化为 0xCC，这个值是有特殊意义的，它是 x86 指令集的 int 3 指令，
刚好是一个中断指令，这样进程在附加调试器的情况下就很容易定位到违规操作执行的位置，
结合调用栈就可以很块定位问题所在。

--------

## 参考链接 ##
1. [efence - Electric Fence Malloc Debugger](http://linux.die.net/man/3/efence)
2. [Electric Fence tutorial](http://www.parl.clemson.edu/~wjones/dev/node19.html)
