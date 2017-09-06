---
layout: post
title: 使用 strace+ 跟踪系统调用和信号
date: 2013-10-21 22:46
comments: true
categories: Linux 编程
---

最近遇到了奇怪的现象，一个进程的物理内存使用量为 7MB 左右，但分配了
250MB左右的地址空间，程序中没有映射大的文件。代码量太大，从源码找问题
不现实，还好有 [strace+](https://code.google.com/p/strace-plus/) 这神器，它可以跟踪系统调用和各种信号，它收集到的
信息还能保持高可读性。相比 strace，strace+ 还能够记录系统调用的调用栈，这样
可以方便的看出到底是谁调用了它。它也是分析源码和简单分析性能瓶颈的好工具。   
ptrace 函数是 strace 实现的关键，通过 ptrace 可以操作其他进程的内存，设置断点等。
```c
long ptrace(enum __ptrace_request request, pid_t pid,
                   void *addr, void *data);
```
strace+ 源码托管在 googlecode 上，它的文档也没有
同步更新。

## 安装 ##

```shell
$ git clone https://code.google.com/p/strace-plus/
$ autoreconf -f -i
$ ./configure
$ make
$ cp strace strace+
```

编译生成的 strace+ 和 strace 的用法一样，但有件事在 **Quick-start guide** 没到提到，
那就是如果想要 strace+ 生成带有调用栈的信息，必须指定 strace+ 的 -k 参数，否则效果
会和 strace 一样。我为此折腾了好久，最后在 [Quick-start guide should include '-k'](https://code.google.com/p/strace-plus/issues/detail?id=4)
中找到答案(这算是开源软件的特点吧：缺乏文档。); )。

先跑一下官网的 demo，执行
```shell
$ strace+ -o hello.out ./hello
```

### 解析 hello.out 查看调用栈 ###
```shell
$ python scripts/pretty_print_strace_out.py hello.out --trace
```

### 或者以树的形式查看调用栈 ###
```shell
$ python scripts/pretty_print_strace_out.py hello.out --tree
```

<!-- more -->

--------

## 使用 ##

strace+ 的使用方式如下：
```shell
$ strace [-CdffhiqrtttTvVxxy] [-In] [-eexpr]... [-acolumn] [-ofile] [-sstrsize] [-Ppath]... -ppid... / [-D] [-Evar[=val]]... [-uusername] command [args]

$ strace -c[df] [-In] [-eexpr]... [-Ooverhead] [-Ssortby] -ppid... / [-D] [-Evar[=val]]... [-uusername] command [args]
```


### strace 常用选项 ###

* **-p**
附加到指定的进程中。可以同时指定多个 -p 选项同时跟踪多个进程。按下 Ctrl+C 结束
strace+ 结束对进程的跟踪并让它们继续运行。

* **-c**
统计系统调用消耗的内核时间，调用次数，错误次数等。

* **-f**
跟踪指定进程和它的子进程。

* **-r**
进入系统调用时的相对时间戳。

* **-T**
显示每个系统调用所话的时间。

* **-e**
-e expr ：expr 指定要跟踪的内容，常见的有：
    1. trace=open,!close
       表示跟踪 open，但不跟踪 close。
    2. trace=file
        只跟踪和文件操作相关的调用。这样的类型还有 process, network, signal,
        ipc, desc（和文件文件描述符相关的）。
    3. signal=...
        跟踪和指定的信号。如 signal=SIGIO,!SIGTERM 。
    4. read=... 将从指定描述符中读取的数据以十六进制和ASCII格式显示。如 -e read=
        3,5。
    5. write=... 与read 类似。

* **-o**
将信息输出到指定的文件中。

* **-E**
-E var=val  设置环境变量。
-E var      移除环境变量。
运行 command 指定的命令之前设置或移除环境变量。

--------

## 应用场景 ##

可以参考下面的文章。     

1. [7 Strace Examples to Debug the Execution of a Program in Linux](http://www.thegeekstuff.com/2011/11/strace-examples/)
2. [Chapter 17. Tracing Tools](http://doc.opensuse.org/documentation/html/openSUSE/opensuse-tuning/cha.tuning.tracing.html)

--------

## 参考链接 ##
1. [strace-plus](https://code.google.com/p/strace-plus/)
2. [Building strace-plus](http://www.askapache.com/linux/building-strace-plus.html)
