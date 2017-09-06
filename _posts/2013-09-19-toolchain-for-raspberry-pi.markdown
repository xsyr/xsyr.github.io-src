---
layout: post
title: "toolchain for Raspberry Pi"
date: 2013-09-19 13:41
categories: Linux Raspberryi
tags: IoT RaspberryPi
---

前段时间买了个 Raspberry Pi，它很适合用来做小白鼠。;) 用它来做一下小实验还是很不错的，
总是在虚拟机里跑越来越觉得不方便。我装的是Pedora，但是直接在板上编译大一点的程序是不科学的，
所以建立一个交叉编译环境是必须的。现在工作大多都在用 C++，平时也关注 C++ 11 标准，所以交叉编译环境
必须支持 C++ 11 的语法。GCC 4.8.1 和 Clang 3.3 都已经全部支持 C++ 11 新特性，
所以这个交叉编译环境会包含 GCC 4.8.1 和 Clang 3.3。建立 toolchain 所需要的组件列如下：    

1.  linux kernel 3.6.11
2.  gmp
3.  mpfr
4.  mpc
5.  isl
6.  cloog
7.  binutils
8.  eglibc
9.  libelf
10. GCC 4.8.1
11. Clang 3.3



先设置好 toolchain 的安装路径：
```shell
$ TOOL_CHAIN_DIR=/opt/arm-rpi-toolchain
$ TARGET_DIR=$TOOL_CHAIN_DIR/arm-rpi-tools
$ SYSROOT_DIR=$TOOL_CHAIN_DIR/sysroot
```

Raspberry Pi 使用的是 arm1176jzf-s CPU，根据其支持的参数设置好需要的编译选项：
```
$ ARCH=armv6zk
$ CPU=arm1176jzf-s
$ WITH_FLOAT=hard
$ WITH_ABI=aapcs-vfp
$ WITH_FPU=vfp
$ HOST_ALIAS=$MACHTYPE
$ TARGET_ALIAS="armv6-rpi-linux-gnueabihf"
$ PKGVERSION="arm toolchain for rpi"
```

**TARGET_ALIAS** 是一个很重要的参数，它的命名规则是这样的：`arch[-vendor][-os]-abi`。
[参考](http://stackoverflow.com/questions/13797693/what-is-the-difference-between-arm-linux-gcc-and-arm-none-linux-gnueabi)。
这个值选用 **armv6** 是出于 Clang 的考虑 —— 见后面的说明。
它的值会作为交叉编译程序的前缀， 如：    
*armv6-rpi-linux-gnueabihf-gcc  armv6-rpi-linux-gnueabihf-g++* 等。

**TARGET_DIR** 用于存放编译生成的运行于 host 的程序的目录。它的目录结构如下：
![toolchain-rpi-target-dir](/assets/img/toolchain-rpi-target-dir.png)

**SYSROOT_DIR** 是一个非常关键的目录，用于存放交叉编译生成的运行于 target 的头文件，
库文件等。交叉编译器在编译和链接时会自动到这个目录下查找需要的文件或库。
这个目录的结构和 host 的根目录结构相似。如图：    
![toolchain-rpi-sysroot-dir](/assets/img/toolchain-rpi-sysroot-dir.png)


## 安装 Linux 头文件 ##

Pedora 是基于 Linux 3.6.11 的内核，所以这里安装的 Linux 头文件也是选择 3.6.11 内核。
先到 [kernel.org](http://kernel.org) 下载 Linux 3.6.11 的源文件，将其解压目录 $linux并安装：
```shell
$ cd $linux
$ make headers_check
$ make ARCH=arm INSTALL_HDR_PATH=$SYSROOT_DIR/usr headers_install
```


## 安装 gmp  ##

```shell
$ cd $gmp
$ mkdir build
$ cd build
$ ../.bootstrap
$ ../configure --prefix=$TARGET_DIR --disable-shared --enable-static
$ make -j8 && make check && make install && make clean
```

参数 `--disable-shared` 是因为编译 gcc 时会依赖 gmp，不需要生成动态库。
如果生成动态库，必须将安装目录添加到 **LD_LIBRARY_PATH** 中。
```shell
$ export LD_LIBRARY_PATH="$TARGET_DIR/lib64:$LD_LIBRARY_PATH"
```

如果 host 是 32bit 的系统，则将 **lib64** 改为 **lib**。    
如果 host 是 64bit 的系统，则需要在 **lib64** 同级的目录创建 **lib** 的软链接
指向 **lib64**。

## 安装 mpfr ##

```shell
$ cd $mpfr
$ autoreconf -i

$ ./configure                \
    --prefix=$TARGET_DIR   \
    --enable-thread-safe   \
    --with-gmp=$TARGET_DIR \
    --enable-static        \
    --disable-shared

$ make -j8 && make install && make clean
```

## 安装mpc ##
```shell
$ cd $mpc
$ autoreconf -i

$ ./configure                 \
    --prefix=$TARGET_DIR    \
    --enable-thread-safe    \
    --with-gmp=$TARGET_DIR  \
    --with-mpfr=$TARGET_DIR \
    --enable-static         \
    --disable-shared

$ make -j8 && make install && make clean
```

## 安装 isl ##
```shell
$ cd $isl
$ ./configure                      \
   --prefix=$TARGET_DIR          \
   --with-gmp-prefix=$TARGET_DIR \
   --enable-static               \
    --disable-shared

$ make -j8 && make install
```

## 安装 cloog ##

```shell
$ cd $cloog
$ mkdir build
$ cd build
$ ../configure                           \
    --prefix=$TARGET_DIR               \
    --with-gmp-prefix=$TARGET_DIR      \
    --with-isl-prefix=$TARGET_DIR      \
    --with-isl-exec-prefix=$TARGET_DIR \
    --enable-static                    \
    --disable-shared

$ make -j8 && make install
```

## 安装 binutils ##

```shell
$ cd $binutils
$ mkdir build
$ cd build
$ LDFLAGS="-Wl,-rpath -Wl,$TARGET_DIR/lib" \
../configure                             \
    --prefix=$TARGET_DIR                 \
    --build=$HOST_ALIAS                  \
    --host=$HOST_ALIAS                   \
    --target=$TARGET_ALIAS               \
    --disable-nls                        \
    --disable-multilib                   \
    --disable-werror                     \
    --with-gmp=$TARGET_DIR               \
    --with-mpfr=$TARGET_DIR              \
    --with-mpc=$TARGET_DIR               \
    --with-sysroot=$SYSROOT_DIR          \
    --with-float=$WITH_FLOAT             \
    --with-fpu=$WITH_FPU                 \
    --with-arch=$ARCH                    \
    --with-cpu=$CPU                      \
    --with-tune=$CPU

$ make configure-host
$ make -j8 && make install && make clean
```

## 安装 gcc mini ##

gcc 与 eglibc 是一个鸡生蛋蛋生鸡的问题。编译 eglibc 需要 gcc 的 C语言编译器，
编译 gcc 的 C++编译器需要 eglibc（libstdc++ 依赖 eglibc）。所以只能先编译生成
C语言编译器，再编译 eglibc，最后编译 C++编译器。

```shell
$ cd $gcc
$ mkdir build_mini
$ cd build_mini

$ ../configure                                       \
    --target=$TARGET_ALIAS                         \
    --prefix=$TARGET_DIR                           \
    --build=$HOST_ALIAS                            \
    --host=$HOST_ALIAS                             \
    --disable-nls                                  \
    --disable-shared                               \
    --disable-multilib                             \
    --disable-decimal-float                        \
    --disable-threads                              \
    --disable-libatomic                            \
    --disable-libgomp                              \
    --disable-libitm                               \
    --disable-libmudflap                           \
    --disable-libquadmath                          \
    --disable-libsanitizer                         \
    --disable-libssp                               \
    --disable-libstdc++-v3                         \
    --enable-languages=c                           \
    --with-gmp=$TARGET_DIR --with-mpfr=$TARGET_DIR \
    --with-mpc=$TARGET_DIR --with-isl=$TARGET_DIR  \
    --disable-cloog-version-check                  \
    --disable-isl-version-check                    \
    --with-sysroot=$SYSROOT_DIR                    \
    --with-local-prefix=$SYSROOT_DIR               \
    --with-pkgversion="$PKGVERSION"                \
    --enable-target-optspace                       \
    --enable-c99 --enable-long-long                \
    --with-newlib --without-headers                \
    --with-float=$WITH_FLOAT                       \
    --with-fpu=$WITH_FPU                           \
    --with-arch=$ARCH                              \
    --with-cpu=$CPU                                \
    --with-tune=$CPU

$ make -j8 && make install
```


## 安装 eglibc ##

glibc 不仅实现 ISO C 规定的那些标准函数，还实现了 POSIX，Berkeley Unix，
SVID 和 XPG标准。Linux 的系统调用也是通过 glibc 封装的。eglibc 和 glibc 是二进制兼容的。

```shell
$ cd $eglibc
$ mkdir build
$ cd build
$ BUILD_CC=gcc CC=$TARGET_ALIAS-gcc CXX=$TARGET_ALIAS-cpp \
AR=$TARGET_ALIAS-ar RANLIB=$TARGET_ALIAS-ranlib         \
../configure                                            \
    --prefix=/usr                                       \
    --with-headers=$SYSROOT_DIR/usr/include             \
    --build=$HOST_ALIAS                                 \
    --host=$TARGET_ALIAS                                \
    --disable-profile                                   \
    --without-gd                                        \
    --without-cvs                                       \
    --enable-add-ons                                    \
    libc_cv_forced_unwind=yes                           \
    libc_cv_c_cleanup=yes                               \
    libc_cv_ctors_header=yes

$ make -j8 && make install install_root=$SYSROOT_DIR
```


## 安装 libelf ##

```shell
$ cd $eglibc
$ mkdir build
$ cd build
$ ../configure  --prefix=$TARGET_DIR --disable-shared --enable-static
$ make -j8 && make install
```

## 安装 gcc full ##

```shell
$ cd $gcc
$ mkdir build
$ cd build
$ ../configure                         \
    --target=$TARGET_ALIAS           \
    --prefix=$TARGET_DIR             \
    --build=$HOST_ALIAS              \
    --host=$HOST_ALIAS               \
    --disable-libssp                 \
    --enable-languages=c,c++         \
    --with-gmp=$TARGET_DIR           \
    --with-mpfr=$TARGET_DIR          \
    --with-mpc=$TARGET_DIR           \
    --with-isl=$TARGET_DIR           \
    --disable-cloog-version-check    \
    --disable-isl-version-check      \
    --with-sysroot=$SYSROOT_DIR      \
    --with-local-prefix=$SYSROOT_DIR \
    --disable-multilib               \
    --with-pkgversion="$PKGVERSION"  \
    --enable-threads=posix           \
    --enable-target-optspace         \
    --disable-nls                    \
    --enable-c99                     \
    --enable-long-long               \
    --enable-__cxa_atexit            \
    --enable-symvers=gnu             \
    --with-libelf=$TARGET_DIR        \
    --enable-lto                     \
    --with-float=$WITH_FLOAT         \
    --with-fpu=$WITH_FPU             \
    --with-arch=$ARCH                \
    --with-cpu=$CPU                  \
    --with-tune=$CPU
$ make -j8 && make install
$ cp $TARGET_DIR/$TARGET_ALIAS/lib/libstdc++.* $SYSROOT_DIR/lib/
$ cp $TARGET_DIR/$TARGET_ALIAS/lib/libgcc_s.so* $SYSROOT_DIR/lib/
```


## 安装 Clang ##

编译 Clang 需要很长的时间，我的机器是 i7 2063QM，8线程跑大概需要4个小时。
编译 Clang 的 **--target** 选项的值需要非常注意，虽然 **arm1176jzf-s** 的架构是
armv6zk，但是 Clang 并不认识这个架构名称，它只能识别 armv6,所以这个值影响最终编译生成
的 clang 编译器的 **--target** 选项。如果指定的是 armv6zk，最终生成的编译器的 **target**
 值将是 **arm7tdmi**。这个值可以从 Clang 的 lib/Driver/ToolChains.cpp 的 GetArmArchForMCpu 函数中得知：
```cpp
static const char *GetArmArchForMCpu(StringRef Value) {
  return llvm::StringSwitch<const char *>(Value)
    .Cases("arm9e", "arm946e-s", "arm966e-s", "arm968e-s", "arm926ej-s","armv5")
    .Cases("arm10e", "arm10tdmi", "armv5")
    .Cases("arm1020t", "arm1020e", "arm1022e", "arm1026ej-s", "armv5")
    .Case("xscale", "xscale")
    .Cases("arm1136j-s", "arm1136jf-s", "arm1176jz-s", "arm1176jzf-s", "armv6")
    .Case("cortex-m0", "armv6m")
    .Cases("cortex-a8", "cortex-r4", "cortex-a9", "cortex-a15", "armv7")
    .Case("cortex-a9-mp", "armv7f")
    .Case("cortex-m3", "armv7m")
    .Case("cortex-m4", "armv7em")
    .Case("swift", "armv7s")
    .Default(0);
}
```

执行编译：

```shell
$ cd $clang
$ mkdir build
$ cd build
$ ../configure                                  \
    --target=$TARGET_ALIAS                    \
    --prefix=$TARGET_DIR                      \
    --with-default-sysroot=$SYSROOT_DIR       \
    --with-gcc-toolchain=$TARGET_DIR          \
    --enable-cxx11                            \
    --enable-optimized                        \
    --disable-assertions                      \
    --disable-shared                          \
    --enable-targets=arm                      \
    --with-binutils-include=$binutils/include \
    --with-float=$WITH_FLOAT                  \
    --with-cpu=$CPU                           \
    --with-fpu=$WITH_FPU                      \
    --with-abi=$WITH_ABI
$ make -j8 && make install
```

## 最后 ##

其实到这里已经算是完成了，可以写段代码试试效果。整个安装过程的 shell 文件如下：



## 参考 ##

1. [arm-linux的交叉编译环境的建立](http://blog.chinaunix.net/uid-23095063-id-163101.html)
2. [pietrushnic's world](http://pietrushnic.blogspot.com/search/label/embedded#.Uj1zTFQW1-6)
3. [给像我一样的新手，一套完整的ARM交叉编译环境的搭建过程](http://www.amobbs.com/thread-5462369-1-1.html)
4. [ARM GCC toolchain build](http://www.arklyffe.com/main/2010/08/29/arm-gcc-toolchain-build/)
5. [Linux From Scratch](http://www.linuxfromscratch.org/lfs/view/development/index.html)
6. [Building the GNU ARM Toolchain for Bare Metal](http://imvoid.wordpress.com/2013/05/01/building-the-gnu-arm-toolchain-for-bare-metal/)
7. [Installing GCC: Configuration](http://gcc.gnu.org/install/configure.html)
