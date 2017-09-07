---
layout: post
title: "mix static and dynamic linking"
date: 2013-10-14 23:36
comments: true
categories: 编程 C/C++
---

混合的使用静态库与动态库有时候很有用，比如第三方库只提供了静态库但你不想所有库
都使用静态的，所以不能使用 **-static** 编译选项。反之也一样，不能为了几个动态库
而使用 **-shared** 选项。再如，对性能敏感的模块使用静态编译可以提升性能，
对性能不敏感的模块可以使用动态链接，这样可以有效的减小程序的体积。
这时候能体现出混合使用动静态库的优势。ld 链接程序提供了
两个选项用于指定所引用的库是静态的还是动态的。

```bash
$ ld --help
  ...
  -Bdynamic, -dy, -call_shared
                              Link against shared libraries
  -Bstatic, -dn, -non_shared, -static
                              Do not link against shared libraries
  ...
```


例如：如果想在链接的时候使用  duma 的静态库，其他的库则默认使用动态库。
则可以这样编译：

```bash
$ g++ -g -O0 heap-corruption.cc -o heapC -Wl,-Bstatic,-lduma -Wl,-Bdynamic -pthread
```

这样，链接时 ld 回去找 libduma.a，其他的包括 pthread 会链接到动态库。如果没有
像上面一样使用 pthread，也要保留 **-Wl,-Bdynamic -pthread** ，否则其他也会使用静态库，
通常会出现问题。反正最后指定的链接选项很重要，不管是 **-Wl,-Bdynamic** 还是
**-Wl,-Bstatic**，它指定除了在命令行中显式指定的库之外都会使用这个选项对应类型
的库。
