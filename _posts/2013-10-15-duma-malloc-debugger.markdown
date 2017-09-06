---
layout: post
title: "使用 DUMA 检测 C++ 内存违规访问和内存泄漏"
date: 2013-10-15 20:01
comments: true
categories: 编程 C/C++
---

D.U.M.A 的全称是 Detect Unintended Memory Access，它是 Electric Fence 的加强版，
可参考《[使用 Electric Fence 检测内存越界操作](http://xinsuiyuer.github.io/blog/2013/10/13/use-electric-fence-to-detect-heap-overruns-and-underruns/)》。
它添加了如下特性：

1. 能 Hook malloc(), call(), memalign(), strdup(), operator new, operator new\[\],free(), operator delete 和 operator delete[]。
2. 能够精确的检测到违规方位的指令，并支持使用调试器定位它在源代码中的位置。
3. 能够检测到不匹配的内存分配与释放函数，如：使用 malloc() 分配但却使用 delete 删除。
4. 可以检测内存泄漏。这是 Electric Fence 不支持的。

DUMA 的[文档](http://duma.sourceforge.net/)有些地方并没有同步更新。


## 安装 ##

下载 [DUMA](https://sourceforge.net/projects/duma/)源码并解压，进入源文件目录编译
并安装：
```shell
$ gmake
$ gmake install libdir=/usr/lib64
```

如果是 32bit 系统，则不需要指定 **libdir** 目录，默认会安装到 **/usr/lib**。DUMA 包含
了两个重要的文件 **libduma.a** 和 **libduma.so.0.0.0**，使用方法和 Electric Fence 类似。



## 高级应用 ##

DUMA 和 Electric Fence 一样，同样支持通过变量来控制其行为，只不过比 Electric Fence
要多。

1. ### DUMA_ALIGNMENT ###
   对应 **EF_ALIGNMENT**。
2. ### DUMA_PROTECT_BELOW ###
   对应 **EF_PROTECT_BELOW**。
3. ### DUMA_FILL ###
   对应 **EL_FILE**，默认为 0xFF。
3. ### DUMA_SLACKFILL ###
   DUMA内部分配内存时以页为单位，如果申请的内存大小小于页大小，则未使用的空间(“无人区”)
   会填充 **DUMA_SLACKFILL** 指定的值。默认为 0xAA。
3. ### DUMA_CHECK_FREQ ###
   对于啥面提到的"无人区"，这个值指定检查这个区域的频率，n 代表多少次内存分配或释放
   时就去检查；如果为 1 则表示每次内存分配和释放都回去检查；默认为 0 ，表示只有在
   内存释放的时候才去检查。频率越高性能损耗越大。
4. ### DUMA_ALLOW_MALLOC_0 ###
   对应 **EF_ALLOW_MALLOC_0**。
5. ### DUMA_MALLOC_0_STRATEGY ###
   当 malloc(0) 的参数为 0 时的返回值策略:
   0 - 和 DUMA_ALLOW_MALLOC_0 = 0时的行为一样，会终止应用程序。
   1 - 返回 NULL
   2 - 总是返回指向某一个受保护的页(Page)的指针，这样在使用时和 0 一样。
   3 - 返回一个只想受保护的页中间地址。
6. ### DUMA_NEW_0_STRATEGY ###
   当 **new** 的大小参数为 0 时的返回值策略:
   2 - 和 **DUMA_MALLOC_0_STRATEGY** 为2时一样。
   3 - 和 **DUMA_MALLOC_0_STRATEGY** 为3时一样。
7. ### DUMA_PROTECT_FREE ###
   其作用和 **EF_PROJECT_FREE**一样。默认为 -1，表示已经开启。如果为 n(n > 0)，
   则表示允许空闲内存的总大小为 n(KB)。
8. ### DUMA_SKIPCOUNT_INIT ###
   DUMA通常在第一次分配内存是初始化。但在一些系统上可能会和pthread或者其他库
   相冲突。为了使 DUMA 在这种场景下能够正常工作，可以通过设置这个变量控制 DUMA 在
   多少次内存分配操作之后再初始化。
9. ### DUMA_REPORT_ALL_LEAKS ###
   DUMA 通常只会报告那些能查找对应文件名和行号的导致内存泄漏的语句。如果此值为 1
   则会报告所有的内存泄漏错误。默认为 0。
10. ### DUMA_MALLOC_FAILEXIT ###
    很多程序并没有检查内存分配失败的情况，这会导致在失败的情况下会延后才会体现出来。
    设置为正数表示失败时就终止程序。
11. ### DUMA_MAX_ALLOC ###
    表示最多能分配的总的内存大小。如果为正数表示最大能分配 n(KB)。默认为 -1,表示无限制。
12. ### DUMA_FREE_ACCESS ###
    这个选项可以帮助调试器捕捉到内存释放的动作。如果此值为非0,则表示开启。默认关闭。
13. ### DUMA_SHOW_ALLOC ###
    是否在每次进行内存分配和释放时都打印到终端。这有助于检查内存的分配和释放的情况。
    默认关闭。
14. ### DUMA_SUPPRESS_ATEXIT ###
    是否在程序退出时忽略 DUMA 自定义的 exit 函数。这个函数用于检查内存泄漏，通常情况下
    不应该跳过。默认为禁止忽略。
15. ### DUMA_DISABLE_BANNER ###
    禁止打印 DUMA 启动信息。默认不禁止。
16. ### DUMA_OUTPUT_DEBUG ###
    将所有 DUMA 信息打印到调试终端。只在 Windows 下有效并且默认关闭。
17. ### DUMA_OUTPUT_STDOUT ###
    将信息打印到 stdout。默认关闭。
18. ### DUMA_OUTPUT_STDERR ###
    将信息打印到 stderr。默认开启。
19. ### DUMA_OUTPUT_FILE ###
    将信息打印到指定文件中。默认关闭。
20. ### DUMA_OUTPUT_STACKTRACE ###
    打印所有泄漏内存的分配语句的调用栈，只在 Windows 下有效并默认关闭。需要用到映射文件。
21. ### DUMA_OUTPUT_STACKTRACE_MAPFILE ###
    只在Windows 下有效，指向由编译器产生的映射文件。

---------

## 内存泄漏检测 ##

1. ### 对 C 写的代码进行内存泄漏检查 ###
为了收集内存分配的语句所在的位置，DUMA 需要对 malloc() 等函数进行“Hook”，这是用
宏实现的，所以需要包含头文件 **#include <duma.h>**。并链接 **libduma.a** 和
**pthread** 库。

```shell
$ g++ -g -O0 heap-corruption.cc -o heapC -Wl,-Bstatic,-lduma -Wl,-Bdynamic -pthread
```

**-Bdynamic** 和 **-Bstatic** 使用参考《[mix static and dynamic linking](http://xinsuiyuer.github.io/blog/2013/10/14/mix-static-and-dynamic-linking/)》。

2. ### 对 C++ 写的代码进行内存泄漏检查 ###
将 **#include <duma.h>** 改为 **#include <dumapp.h>** 即可。对于 C++，DUMA 还自定义
了new, new\[\], delete 和 delete\[\]操作符。

```c++
void * DUMA_CDECL operator new(DUMA_SIZE_T, const char *, int) throw(std::bad_alloc);
void * DUMA_CDECL operator new(DUMA_SIZE_T, const std::nothrow_t &, const char *, int) throw();
void   DUMA_CDECL operator delete(void *, const char *, int) throw();
void   DUMA_CDECL operator delete(void *, const std::nothrow_t &, const char *, int) throw();

void * DUMA_CDECL operator new[](DUMA_SIZE_T, const char *, int) throw(std::bad_alloc);
void * DUMA_CDECL operator new[](DUMA_SIZE_T, const std::nothrow_t &, const char *, int) throw();
void   DUMA_CDECL operator delete[](void *, const char *, int) throw();
void   DUMA_CDECL operator delete[](void *, const std::nothrow_t &, const char *, int) throw();

```

-----

## 参考链接 ##
[D.U.M.A. - Detect Unintended Memory Access](http://duma.sourceforge.net/)
