---
layout: post
title: "openSUSE 12.3 安装 bumblebee"
date: 2013-09-17 22:45
categories: Linux openSUSE
tags: Linux openSUSE bumblebee
---

## bumblebee 是何方神圣？

[官网](a project aiming to support NVIDIA Optimus technology under Linux) 这么说：
"a project aiming to support NVIDIA Optimus technology under Linux"。明白了吧？
这东西就是用来开启N卡与集显的切换的。自己用 openSUSE 有两年多了，期间尝试过其他几个
版本的发行版，还是觉得她比较好用，这里提供了很多版本的软件，offical的，factory的，
其他贡献者编译的源等，查找起来很方便，不用自己在去编译源码。笔记本是 N53 的，带有
GT540M 显卡，但是无法在 BIOS 里禁用，夏天运行热的不行，要是能和 Windows 那么安静
凉快的跑，我也不想这么折腾了。可那有什么办法，坑爹的 Nvidia，Linus Torvalds 曾为此
竖起中指，破口大骂："So Nvidia, Fuck you!"。不久后 Nvidia 就宣布 Optimus 将来支持
Linux，然后.....没下文了。


-----

## 创建 bumblebee 和 video 用户组

```shell
$ groupadd bumblebee
$ groupadd video
$ usermod -a -G bumblebee,videl  [你的用户名]
$ groups
```
一定要确保自己在 bumblebee 和 video 组里。可以用下面的命令查看:    
```shell
$ groups
```

----------

## 添加 Overman79's 源 ##

```shell
$ zypper ar http://download.opensuse.org/repositories/home:/Overman79:/Laptop/openSUSE_12.3/ Overman79
```

---------

## 安装 dkms dkms-nvidia  dkms-bbswitch ##

```shell
$ zypper in dkms dkms-nvidia dkms-bbswitch bumblebee primus x11-video-nvidia
```

安装时会很需要挺长一段时间，而且没有进度条，别怀疑它，耐心等待。    
刚开始我曾以为安装错误了，就 Ctrl + c，继续安装后面的组件，后来才发现这个是行不通的。

------

## 开启 dkms 和 bumblebeed 服务 ##

```shell
$ systemctl enable dkms
$ systemctl enable bumblebeed
```

dkms 全称 **Dynamic Kernel Module Support**，
它用来在更新内核之后重新编译前面安装的那些组件。   
重启！！！

-------

## 看看N卡关闭了没 ##

```shell
$ cat /proc/acpi/bbswitch
$ primusrun --status
```

第一个命令应该显示 **OFF**，第二个命令应该显示 **Discrete video card is off**.   
要是不行的话执行下面的命令：    

```shell
$ rmmod nvidia
$ tee /proc/acpi/bbswitch <<<OFF
```

再看看是否可行，不行的话 Google 去吧!!!

-----

## 把 nvidia.ko 列入黑名单，重新生成新的 initrd ##

```shell
$ cd /etc/modprobe.d
$ echo 'blacklist nvidia' >> 50-blacklist.conf
$ echo 'blacklist nvidia' > 50-nvidia.conf
$ echo 'blacklist nvidia' > nvidia-default.conf
$ echo 'options bbswitch load_state=0 unload_state=0' > 50-bbswitch.conf
```

上面的文件可能会随着 bumblebee 的版本而改变，
但名字没有太大变化，根据实际情况修改即可。

打开 ``/etc/sysconfig/kernel`` ，把所有和 nvidia 相关的都注释掉。


```shell
$ mkinitrd
```

## 参考链接

1. [bumblebee wiki](https://github.com/Bumblebee-Project/Bumblebee/wiki)
2. [openSUSE 12.3: How to install 'bumblebee' for NVIDIA Optimus VGA](http://smithfarm-thebrain.blogspot.cz/2013/03/opensuse-123-how-to-install-bumblebee.html)
3. [Setup bumblebee and primus in openSUSE 12.3](http://forums.opensuse.org/english/get-technical-help-here/hardware/484188-setup-bumblebee-primus-opensuse-12-3-a.html)
4. [Right nvidia optimus driver configuration](http://forums.opensuse.org/english/get-technical-help-here/64-bit/479942-right-nvidia-optimus-driver-configuration.html)
