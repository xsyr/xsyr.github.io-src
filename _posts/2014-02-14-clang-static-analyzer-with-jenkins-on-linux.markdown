---
layout: post
title: "clang static analyzer with jenkins on linux"
date: 2014-02-14 21:46
comments: true
categories: 编程 C/C++
---

clang 是一个优秀的编译器，基于 clang 的 clang static anayler 静态检查工具也是
开发过程中不可缺少的。这里介绍在 jenkins 集成 clang static analyer 的方法。

## 安装 ##
安装请参考 [Clang Static Analyzer - 静态代码分析工具](http://xinsuiyuer.github.io/blog/2014/01/12/clang-static-analyzer/)。

## 安装 clang-scanbuild-plugin 插件 ##
安装过程很简单，在 jenkins 插件管理页面就可以方便的安装，
`http://your-jenkins-ci-server/pluginManager/available`。

<!-- more -->

## 配置 clang-scanbuild-plugin ##
由于 clang-scanbuild-plugin 只支持 Mac 平台，在 linux 上需要做一些修改。
1. 首先配置 clang-scanbuild-plugin  
进入 `http://your-jenkins-ci-server/configure`，找到 *Clang Static Analyzer installations*，
设置 scan-build 所在的路径。   
Name 填 scan-build    
Installation directory 填写 scan-build 所在的路径。    
保存

2. 添加项目的 scan-build 构建步骤
进入项目的配置页面， *Add build step* 选择 *Clang Scan-Build* ，    
在这里会看到 *Clang scan-build installation* 自动选择前面配置的 *scan-build* 的安装配置信息。    
*Additional scan-build arguments* 填 `--use-analyzer=/usr/bin/clang -enable-checker alpha -enable-checker core -enable-checker security -enable-checker unix`。

3. 修改 scan-build 源码
因为 *clang-scanbuild-plugin* 只支持 *XCode* ，所以必须对源码进行修改使其能在 linux
 上工作。步骤如下：

一是禁用 scan-build 的 -v 参数， *clang-scanbuild-plugin* 插件默认添加了这个参数，
导致在执行代码检查时 *Console Output* 充斥太多的执行细节，我们不需要这么详细。    
打开 scan-build，屏蔽处理 -v 参数的语句，将    
```perl
  if ($arg eq "-v") {
    shift @ARGV;
    $Verbose++;
    next;
  }
```

改为

```perl
  if ($arg eq "-v") {
    shift @ARGV;
      #$Verbose++;
    next;
  }
```

--------------------

二是禁止其执行 xcodebuild 命令。在 *RunBuildCommand* 函数中将   
```perl
  my $IgnoreErrors = shift;
  my $Cmd = $Args->[0];
  my $CCAnalyzer = shift;
```

改为

```perl
  my $IgnoreErrors = shift;
  #my $Cmd = $Args->[0];
  my $Cmd = "make";
  my $CCAnalyzer = shift;
```

```perl
  return (system(@$Args) >> 8);
```

改为

```perl
  chdir("scan-build-dir");
  return (system("make -B") >> 8);
```

------------

三是为 scan-build 准备编译目录和 *Makefile*。这一步是在项目的配置页面的 *`Execute Shell`*
中添加脚本命令：
```shell
$ mkdir -p scan-build-dir
$ cd scan-build-dir
$ cmake -DCMAKE_C_COMPILER=ccc-analyzer -DCMAKE_CXX_COMPILER=c++-analyzer -DCMAKE_C_FLAGS=" -c " -DCMAKE_CXX_FLAGS=" -c " ..
```

注意这一步与上一步提到的 `chdir("scan-build-dir");` 目录相对应。

## 着色 make 的输出信息 ##
CMake 在选择 Unix Makefile 生成器时，如果当前的终端是 tty 类型，则默认会着色当前的编译进度。
但是 *clang-scanbuild-plugin* 重定向了输出信息，而它不是 tty 类型的终端，所以不再有着色的进度信息。

首先安装 *AnsiColor* 插件

然后欺骗 CMake，告诉它现在是 tty 类型的终端，这里使用 *LD_PRELOAD* 进行 *API Hook*。

编写如下代码：
```c
/**
 * Overrides the glibc function. Will always return true.
 *
 * Note: Although this should be ok for most applications it can
 * lead to unwanted side effects. It depends on the question
 * why the programm calls isatty()
 */
int isatty(int param) {
    return 1;
}
```

将上面的代码编译为 *libisatty.so*。

最后修改 *scan-build* 的源码
```perl
  chdir("scan-build-dir");
  return (system("make -B") >> 8);
```

改为

```perl
  chdir("scan-build-dir");
  return (system("LD_PRELOAD=/path/to/libisatty.so make -B") >> 8);
```

大功告成！！！！
