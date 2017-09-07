---
layout: post
title: "valgrind Memcheck 检测内存错误 - 使用"
date: 2013-10-25 23:08
comments: true
categories: 编程 C/C++
---

说到 Valgrind，C/C++ 程序员恐怕没有谁没听说过它，要是如此真是 out了。Valgrind 是
一个测试框架，它包含各种工具：

1. **Memcheck**, **SGcheck** 是内存错误检测工具。
2. **Cachegrind**, **Callgrind** 缓存分析工具。
3. **Helgrind**, **DRD** 是线程错误检测工具。在编写多线程程序时很有用。
4. **Massif**, **DHAT** 是堆分析工具。
5. **BBV** is an experimental SimPoint basic block vector generator. It is useful to people doing computer architecture research and development.
6. 还有其他的工具[Variants and Patches](http://valgrind.org/downloads/variants.html)

Valgrind 是非侵入式的，所以使用它可以完成很多的检测任务而不需要对程序源码进行任何
修改，除非需要一些高级的功能。Valgrind 运行在一个模拟的 CPU 上，它是 Valgrind 的核心。
然后各种检测在它之上完成相应的工作。这也是为什么 Memcheck 工具不需要像 **Memcheck**,
**D.U.M.A**那样需要引用相应的头文件，也可以很漂亮的完成工作。    
也正因为如此，在 Valgrind 上运行的程序会慢很多。


------


## 安装 ##

很多 Linux 发行版的源都有已经编译好的二进制包，直接安装即可。openSUSE下的安装：
```bash
$ zypper install valgrind
```

也可以[源码](http://valgrind.org/downloads/)安装：
```bash
$ ./configure; make; sudo make install
```


## Memcheck 能检测到的错误 ##

1. **非法读写内存**
当读写无效的内存地址时（如：已释放内存块或者未分配的地址等），
它会报错并给出发生错误的地方和调用堆栈。可以指定 **--read-var-info=yes** 获得更加详细
的信息，但程序会运行的更慢。

2. **使用未初始化的变量**
未初始化的值主要来自未初始化的本地变量和未初始化的堆内存块。只有这个值会影响程序的
行为时 Valgrind 才会报错。例如将它作为调用参数或者作为分支条件。可以指定
**--track-origins=yes** 获得详细的信息。

3. **使用为初始化的变量或者无效的地址作为系统调用的参数**
Valgrind 会对系统调用的所有参数做检查，包括：
    1. 检查变量是否已经初始化
    2. 如果系统调用需要读某个内存块，则检查该内存块是否已经初始化。
    3. 如果系统调用需要写某个用户指定的内存块，则检查该内存块是否是有效和已初始化。

4. **非法释放内存块**
指的是 double-free 或者 传递给 free/delte 的指针没有指向内存块的起始位置。

5. **分配和释放内存块的函数不匹配**
如使用 free 分配的内存块使用 delete 去释放会导致报错。

6. **目标内存块和源内存块重叠**
对于像 memcpy, strcpy, strncpy, strcat, strncat 这样的内存块拷贝函数，需要指定
两个参数 src 和 dst，如果这两个参数分别指定的内存块存在重叠的区域则会报错。

7. **内存泄露**
当程序退出时 Memcheck 会报告内存的释放情况。程序退出时还存在的内存块分为四种类型：
   1. 肯定丢失的：即没有任何指针指向那些内存块。
   2. 间接丢失的：还有指针指向那些内存块，但这些指针在“肯定丢失”的内存块中。
   3. 可能丢失的：还有指针指向那些内存块，但这些指针没有指向那些内存块的起始位置。
   4. 仍然可访问的块：还有指针指向那些内存块。


## Valgrind 的使用 ##

为了使 Memcheck 能够精确的报告错误的位置，编译程序时必须指定 **-g** 以便生成的
二进制文件中包含有调试信息。如果可以容忍程序运行得慢一点，可以指定 **-O0**，这样
就可以准确的报告错误所在的行数。大部分时候 **-O1** 也是可以正常的定位。但最好不要
指定 **-O2** 或者更高的优化级别，这样导致无法检测使用未初始化的变量。因为这些变量
可能已经被优化而不存在了。   
而且，不能同时与其他的 allcator 同时使用，否则会导致 Valgrind 无法正常正常工作。

Valgrind 的调用格式如下：
```bash
valgrind --tool=memcheck [valgrind-options] your-prog [your-prog-options]
```

**--tool** 参数指定使用的检测工具，即上面提到的。默认为 memcheck。

Valgrind 生成的报告信息如下：
```
==10772== Memcheck, a memory error detector
==10772== Copyright (C) 2002-2012, and GNU GPL'd, by Julian Seward et al.
==10772== Using Valgrind-3.8.1 and LibVEX; rerun with -h for copyright info
==10772== Command: ls -l
==10772==
...
==10772==
==10772== HEAP SUMMARY:
==10772==     in use at exit: 20,346 bytes in 36 blocks
==10772==   total heap usage: 641 allocs, 605 frees, 113,106 bytes allocated
=10772==
==10772== LEAK SUMMARY:
==10772==    definitely lost: 0 bytes in 0 blocks
==10772==    indirectly lost: 0 bytes in 0 blocks
==10772==      possibly lost: 0 bytes in 0 blocks
==10772==    still reachable: 20,346 bytes in 36 blocks
==10772==         suppressed: 0 bytes in 0 blocks
==10772== Rerun with --leak-check=full to see details of leaked memory
==10772==
==10772== For counts of detected and suppressed errors, rerun with: -v
==10772== ERROR SUMMARY: 0 errors from 0 contexts (suppressed: 2 from 2)
```

10772 指的是进程 id。报告中包含 堆的使用情况和内存泄漏信息。如果出现内存泄漏，则可以
再次使用 **--leak-check=full** 获得更详细的信息。

--------------

## Valgrind 相关的选项 ##

* **错误信息输出位置**
  错误信息可以输出到指定的文件或者 socket 中。
  * `--log-fd=file-descriptor`   
    输出到描述符所指定的文件中。默认是 2(stderr)，
    但某些情况下 stderr 另有所用，这个选项就用得上了。

  * `--log-file=filename`   
    输出到制定的文件中。

  * `--log-socket=ip:port`   
    输出到制定的 socket 中，如：192.168.0.1:8080。

    Valgrind 自带了一个 valgrind-listener 工具，可以在目标主机上运行它并指定其监听
    的端口。   
    `valgrind-listener [--exit-at-zero|-e] [port-number]`

* **基本选项**
  * `-q, --quiet`   
    安静模式，只打印错误报告信息。

  * `--trace-children=<yes|no> [default: no]`   
    如果为yes，则跟踪由 exec 系列函数所创建子进程。

  * `--trace-children-skip=patt1,patt2,...`    
    在 --trace-children=yes 的情况下，不跟踪 patt 匹配到的可执行文件名的进程。
    patt 可以使用 \* 和 ? 通配符。

  * `--trace-children-skip-by-arg=patt1,patt2,...`    
    与 --trace-children-skip 类似，只是匹配传递给子进程的参数而不是可执行文件名。

  * `--child-silent-after-fork=<yes|no> [default: no]`    
    如果为 yes，则不会输出任何通过 fork 产生的子进程的日志。

  * `--vgdb=<no|yes|full> [default: yes]`    
    如果为 yes 或者 full，则允许 GDB 附加到由 Valgrind 运行的程序中。full 可以使
     GDB 更加精确的设置断点。

  * `--vgdb-error=<number> [default: 999999999]`    
    在 --vgdb=yse|full 的情况下，只有错误数数量达到这个值 Valgrind 才会暂停程序的
    执行并且等待 GDB 附加进来。可以设置为 0，这样程序未运行就可以附加 GDB 进行调试和
    放置断点。

  * `--track-fds=<yes|no> [default: no]`    
    如果为 yes，则会在程序退出之后打印未关闭的文件描述符和其相关的文件名或者 socket
    的详细信息。

  * `--time-stamp=<yes|no> [default: no]`   
    如果为 yes，则在每一条信息前面加上时间戳。

* **与错误信息相关的选项**
  * `--demangle=<yes|no> [default: yes]`   
    如果为 yes, 则还原由编译器生成的修饰后的 C++ 符号。

  * `--num-callers=<number> [default: 12]`    
    当显示调用堆栈时显示的调用链的深度。如果发生错误时最多只会显示 4 而不会被
    这个值影响。

  * `--error-limit=<yes|no> [default: yes]`   
    如果为 yes，则在错误总数达到 10,000,000 或者 1000条不同类型的错误后，停止
    错误信息的打印。

  * `--error-exitcode=<number> [default: 0]`    
    Valgrind 检测到错误时的退出码。

  * `--show-below-main=<yes|no> [default: no] `    
    调用堆栈中是否显示调用 main 函数的调用者。

  * `--fullpath-after=<string> [default: don't show source paths] `
    指定错误报告中的文件的前缀路径。

  * `--suppressions=<filename> [default: $PREFIX/lib/valgrind/default.supp]`
    此文件中标识哪些错误会被忽略而不打印。最多制定 100 个文件。

  * `--gen-suppressions=<yes|no|all> [default: no] `
    如果为 yes，则在显示每一条错误信息之后会停止并显示：   

    `---- Print suppression ? --- [Return/N/n/Y/y/C/c] ----`   
    如果选择 y 则会生成错误过滤的信息，可以将此信息复制到 错误过滤文件中。

  * `--db-attach=<yes|no> [default: no] `   
    如果为 yes，则在显示每一条错误信息之后停止并显示：

    `---- Attach to debugger ? --- [Return/N/n/Y/y/C/c] ----`    
    选择 y 则会启动 GDB 并附近到当前进程中。如果为 c 跳过并不再询问。

  * `--db-command=<command> [default: gdb -nw %f %p] `
    当 --db-attach=yes 时，执行启动 GDB 的命令。

  * `--max-stackframe=<number> [default: 2000000] `   
    最大栈帧的大小。如果栈顶指针超过这个值，Memcheck 会认为使用新的栈。

  * `--main-stacksize=<number> [default: use current 'ulimit' value] `   
    main 线程的栈大小。默认为无限制。

* **内存分配相关的选项**
  * `--alignment=<number> [default: 8 or 16, depending on the platform] `    
    分配的内存块的起始地址的对齐大小。必须是 2的N次方。

  * `--redzone-size=<number> [default: depends on the tool] `    
    Memcheck 会在每个内存块的前后保留一定大小的区域（“红区” or “无人区”），已检测
    内存块的越界访问。这个值越大就越容易检测到步进越大的越界访问。但内存消耗也增大。

-------

## Memcheck 选项 ##

* `--leak-check=<no|summary|yes|full> [default: summary] `    
  **summary** ：错误的个数。**yes|full** ：给出每个错误的详细信息。**full** 则列出
  “肯定丢失”和“可能丢失”的内存块的信息。

* `--show-possibly-lost=<yes|no> [default: yes] `    
  yes 则列出“可能丢失”的内存块的信息。

* `--leak-resolution=<low|med|high> [default: high] `     
  内存泄露信息中调用栈的详细程度。级别越高显示的调用栈层数越高越详细。

* `--show-reachable=<yes|no> [default: no] `    
  yes 则显示“间接丢失”和“仍然可访问”的内存块的信息。

* `--undef-value-errors=<yes|no> [default: yes] `   
  是否在使用 为初始化的值 时报告错误。

* `--track-origins=<yes|no> [default: no] `   
  当使用了 未初始化的值 时是否显示这个值的来源。默认情况下只会报告这个值被使用的地方。
  通常只要知道它在什么地方被使用，就可以很块定位到这个值的来源。

* `--partial-loads-ok=<yes|no> [default: no] `    
  经过字对齐之后的内存块，会有一部分是用来填充的。如果为 yes，则允许读取包含填充部分
  的内存。反之不然。

* `--freelist-vol=<number> [default: 20000000] `    
  当使用 free 或者 delete 释放内存块时，Memcheck 会将这些内存块放到空闲列表中，当使用
  malloc 或者 new 分配新的内存时 Memcheck 会继续像 OS 申请而暂不使用这些空闲的内存块。
  这样可以帮助 Memcheck 检测到更多的无效内存读写的情况。因为有些违规操作可能要延迟很久
  才发生。    
  这个值限制空闲列表的最大内存大小(以字节为单位)。

* `--freelist-big-blocks=<number> [default: 1000000] `    
  当上面提到的空闲列表要被用来重新分配时，Memcheck 会优先使用大小大于 --freelist-big-blocks
  的内存块。这样能够更容易发现“野指针”。

* `--ignore-ranges=0xPP-0xQQ[,0xRR-0xSS] `   
  Memcheck 不会检查这些区域内的内存是否是可访问的。

* `--malloc-fill=<hexnumber> `   
  当使用 malloc 和 new 分配内存时将使用这个值进行填充。这有助于发现内存被破坏的情况。

* `--free-fill=<hexnumber> `   
  当使用 free, delete 等释放内存时将使用这个值进行填充。

--------

## 设置常用的选项 ##

对于那些常用的选项，总是在命令行中指定不是个好主意。Valgrind 提供三个地方可以
设置这些常用的选项。
1. ~/.valgrindrc
2. $VALGRIND_OPTS
3. ./.valgrindrc
Valgrind 会按照从上往下的顺序读取，命令行中指定的相同选项会覆盖它们。每个选项应该
以工具名开头+冒号+选项=值的格式设置。如：
```
--memcheck:leak-check=yes
```

-------

## 参考链接 ##
1. [Valgrind User Manual](http://valgrind.org/docs/manual/manual.html)
2. [Using Valgrind to Find Memory Leaks and Invalid Memory Use](http://www.cprogramming.com/debugging/valgrind.html)
