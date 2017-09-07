---
layout: post
title: "cppcheck - 静态代码分析工具"
date: 2014-01-11 14:21
comments: true
categories: 编程 C/C++
---

[cppcheck](http://cppcheck.sourceforge.net/) 是一个静态代码分析工具。它可以静态检查
内存泄漏，访问越界等错误，当然不会是很全面和精确的，但不失为程序员的好助手。简单用法：

```bash
$ cppcheck [options] [files or paths]
$ cppcheck samples/memleak/bad.c
$ cppcheck samples/
```


##安装##

因为要支持 rules，所以安装之前必须安装 PCRE。

```bash
$ cd src
$ tar -xjf cppcheck-1.63.tar.bz2
$ cd cppcheck-1.63
$ make SRCDIR=build CFGDIR=~/bin/cpp-check/cfg HAVE_RULES=yes -j8 -B
$ make install BIN=~/bin/cpp-check
$ cp -R cfg ~/bin/cpp-check
$ cd ~/bin
$ ln -s cpp-check/cppcheck cppcheck
$ ln -s cpp-check/cppcheck-htmlreport cppcheck-htmlreport
```

cppcheck 还有一个 gui 版本，是基于 Qt 的。必须先安装    

* libqt4-core
* libqt4-gui
* libqt4-dev
* qt4-dev-tools
* qt4-qmake

```bash
$ cd cppcheck-1.63/gui
$ qmake HAVE_RULES=yes
$ make -j8
$ lupdate
$ lrelease
$ cp cppcheck-gui ~/bin/cpp-check
$ ln -s ~/bin/cpp-check/cppcheck-gui ~/bin/cppcheck-gui
$ mkdir lang
$ cp *.qm ./lang
$ cp -R lang ~/bin/cpp-check
$ cp icon.png ~/bin/cpp-check
$ cp icon.svg ~/bin/cpp-check
```
