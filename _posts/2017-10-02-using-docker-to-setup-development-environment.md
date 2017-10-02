---
layout: post
title: '使用 Docker 搭建开发环境'
date: 2017-10-02 12:30:14 +0800
categories: docker
tags: docker
---

公司的线上机器装的是 CentOS 6.3, 系统自带的 gcc 套件版本太老旧(gcc 4.4.7),
我们开发代码已经使用 C++ 11 标准,所以之前在虚拟机的 CentOS 6.3 上编译了 gcc 5.3.

之前一直使用 virtualbox 搭建编译环境, 最近换了超级本,  内存硬盘本来就捉襟见肘.
virtual box 环境一共使用了 16GB 硬盘, 2GB 内存, 一跑起来内存和硬盘容量就变得紧张了.

今天用 docker 替换 virtualbox, 磁盘使用不到 4GB, 内存也就跑应用程序的开销,
不用再给 Guest 系统分配什么内存了. 大致操作过程如下:

# 1. 下载 centos 6.3 镜像
```bash
$ docker pull demeternacl/centos-6.3
```
整个镜像也才不过140MB

# 2. 拷贝 gcc 5.3 编译环境
把 virtualbox 的 gcc 5.3 编译环境拷贝到宿主机, 因为编译环境的某些文件或目录使用了软链接,
所以在 `cp` 的时候要加上 `cp -L`参数, 把软链接指向的文件或目录也要复制一边, 这回导致某些重复.
也可以选择把编译环境用 `tar` 打包,然后直接拿到 docker 的 cetnos 环境解压.
这里选择第一种方式.

# 3. docker centos 安装基本开发环境
启动 docker centos 环境
```bash
$ docker run -v /path/to/gcc-5.3:/usr/local/gcc-5.3 -v /path/to/workspace:/root/workspace -u root -w '/root' --name centos-gcc5.3  -it demeternacl/centos-6.3 /bin/bash
```

安装 Development tools
```bash
$ yum install vim-enhanced
$ yum groupinstall 'Development tools'
```

将 gcc 5.3 的各个目录添加到 shell 的环境变量中(写到 ~/.bashrc)
```bash
export PATH="$PATH:/usr/local/gcc-5.3/bin"
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/gcc-5.3/lib"
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/gcc-5.3/lib64"

alias cd='cd ..'
alias grep='grep --color=auto'

PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
```

接下来可以尝试编译工程代码.


# 4. 打包镜像分享给其他伙伴
```bash
$ docker commit centos-gcc5.3 my:centos-gcc5.3
$ docker save -o centos-gcc5.3.tar my:centos-gcc5.3
```
接下来可以将这个 tar 分发给其他伙伴使用了(当然还得把 gcc 5.3 的编译一起拷贝).
