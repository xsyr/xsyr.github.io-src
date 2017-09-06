---
layout: post
title: "valgrind Memcheck 检测内存错误 - GDB"
date: 2013-10-26 16:44
comments: true
categories: 编程 C/C++
---


有时候结合使用 GDB 和 Valgrind 会非常有用，比如当出现了一个错误，用 GDB 附加到
进程中以获得更多的信息。前面提到 程序是运行在 Valgrind 提供的模拟 CPU 上，所以
不能直接附加到 Valgrind 的进程中，那就变成调试 Valgrind 了。Valgrind 提供了 GDB
远程调试机制，可以连接到 Valgrind 实现的 gdbserver 中。步骤如下：

```shell
$ valgrind --tool=memcheck --vgdb=yes --vgdb-error=0 ./heapC
```

`--vgdb` 和 `--vgdb--error` 可以参考前面的文章[valgrind Memcheck 检测内存错误 - 使用](http://xinsuiyuer.github.io/blog/2013/10/25/use-valgrind-memcheck-to-detect-memory-error-1/)。启动之后 Valgrind 会等待 gdb 连接上来。

```
==14669== Memcheck, a memory error detector
==14669== Copyright (C) 2002-2012, and GNU GPL'd, by Julian Seward et al.
==14669== Using Valgrind-3.8.1 and LibVEX; rerun with -h for copyright info
==14669== Command: ./heapC
==14669==
==14669== (action at startup) vgdb me ...
==14669==
==14669== TO DEBUG THIS PROCESS USING GDB: start GDB like this
==14669==   /path/to/gdb ./heapC
==14669== and then give GDB the following command
==14669==   target remote | /usr/lib64/valgrind/../../bin/vgdb --pid=14669
==14669== --pid is optional if only one valgrind process is running
==14669==
```

GDB 通过 vgdb 连接到 Valgrind。
```shell
$ gdb ./heapC
(gdb) target remote | vgdb
```

如果有多个被调试程序同时运行，在执行 target remote | vgdb 时会提示连接到哪个
进程中：
```
(gdb) target remote | vgdb
Remote debugging using | vgdb
no --pid= arg given and multiple valgrind pids found:
use --pid=16988 for valgrind --vgdb=yes --vgdb-error=0 ./heapC
use --pid=17013 for valgrind --vgdb=yes --vgdb-error=0 ./heapC
Remote communication error.  Target disconnected.: Connection reset by peer.
```

可以通过给 vgdb 提供 pid 选项指定连接到哪个进程：
```shell
(gdb) target remote | vgdb --pid=17013
```

连接到调试进程之后就可以使用 GDB 的各种命令调试程序。

------

## 参考链接 ##
1. [Using and understanding the Valgrind core: Advanced Topics](http://valgrind.org/docs/manual/manual-core-adv.html#manual-core-adv.gdbserver)
