---
layout: post
title: "Clang Static Analyzer - 静态代码分析工具"
date: 2014-01-12 00:03
comments: true
categories: 编程 C/C++
---

[Clang Static Analyzer](http://clang-analyzer.llvm.org/index.html) 和 cppcheck 一样，都是代码静态检查工具。
它是 clang 编译器的一部分，在[编译 clang](http://clang.llvm.org/get_started.html#build)后才能使用。
 scan-build 和 scan-view 是用 Perl 写的脚本程序，皆在简化对 Static Analysis 功能
的使用。scan-build 会将结果生保存到 html 中，scan-view 类似一个简单的网页服务器，
可以在浏览器上方便的查看结果。

<!-- more -->

## 安装 ##

在编译安装 llvm/clang 之后，scan-build 和 scan-view 分别在   
`$(SRC)/llvm/tools/clang/tools/scan-build` 和   
`$(SRC)/llvm/tools/clang/tools/scan-view` 目录下。

可以把这两个目录添加到 PATH 路径下，也可以放到 ～/bin 下。
```shell
$ install -d ~/bin/clang-static-analyzer
$ cp -R $(SRC)/llvm/tools/clang/tools/scan-build \
        $(SRC)/llvm/tools/clang/tools/scan-view ~/bin/clang-static-analyzer
$ echo 'export PATH="$PATH:$HOME/bin/clang-static-analyzer/scan-build:$HOME/bin/clang-static-analyzer/scan-view"' >> ~/.bashrc
```

## 使用 ##

### 编译单个文件 ###
```shell
$ scan-build gcc -c main.c
```

`-c` 只是编译而不链接，因为我们只需要做语法检查。scan-build 根据命令行中的编译器的
名称而使用具体的分析器。如果是 gcc/clang，则会使用 ccc-analyzer。如果是 g++/clang++ 则使用
c++-analyzer。它们也是 Perl 写的脚本程序，最终都会调用 `clang --analyze`。

### 结合 make 或 configure ###

```shell
$ scan-build ./configure
$ scan-build make
```

这种方式是通过修改 CC 和 CXX 环境变量的值。


### 结合 CMake 使用 ###

```shell
$ cmake -DCMAKE_C_COMPILER=ccc-analyzer -DCMAKE_CXX_COMPILER=c++-analyzer ..
```

### 例子 ###

```c
int main()
{
    int a[2];
    int i;
    for (i = 0; i < 3; i++)
        a[i] = 0;
    return a[0];
}
```

```shell
$ scan-build --use-analyzer=/usr/bin/clang -enable-checker alpha.security gcc bufferAccessOutOfBounds/bad.c
scan-build: Using '/usr/bin/clang-3.4' for static analysis
bufferAccessOutOfBounds/bad.c:6:14: warning: Access out-of-bound array element (buffer overflow)
        a[i] = 0;
        ~~~~ ^
1 warning generated.
scan-build: 1 bugs found.
scan-build: Run 'scan-view /tmp/scan-build-2014-01-12-144457-32387-1' to examine bug reports.
```

它检测到了数组越界并生成了 html 报告。可以使用 `-o /path/to/output` 指定 html 的存放路径。
根据提示可以使用 scan-view 查看结果。

![clang-static-analyzer-report]/assets/img/clang-static-analyzer-report.png)

------------------------------------

## checker - 检查规则 ##
内置的 checker 存放在 `$(SRC)/llvm/tools/clang/lib/StaticAnalyzer/Checkers` 目录下。
这些 checker 默认情况下并没有全部开启，所以需要根据情况启用合适的 checker。可以使用
`-enable-checker` 和 `-disable-checker` 开启和禁用具体的 checker 或者 某种类别的
checker。

```shell
$ scan-build -enable-checker alpha.security.ArrayBoundV2 ... # 启用数组边界检查
```

所有支持的 checkers 可以使用如下命令查看：
```shell
$ clang -cc1 -analyzer-checker-help
  alpha.core.BoolAssignment       Warn about assigning non-{0,1} values to Boolean variables
  alpha.core.CastSize             Check when casting a malloced type T, whether the size is a multiple of the size of T
  alpha.core.CastToStruct         Check for cast from non-struct pointer to struct pointer
  alpha.core.FixedAddr            Check for assignment of a fixed address to a pointer
  alpha.core.IdenticalExpr        Warn about unintended use of identical expressions in operators
  alpha.core.PointerArithm        Check for pointer arithmetic on locations other than array elements
  alpha.core.PointerSub           Check for pointer subtractions on two pointers pointing to different memory chunks
  alpha.core.SizeofPtr            Warn about unintended use of sizeof() on pointer expressions
  alpha.cplusplus.NewDeleteLeaks  Check for memory leaks. Traces memory managed by new/delete.
  alpha.cplusplus.VirtualCall     Check virtual function calls during construction or destruction
  ...
  alpha.security.ArrayBound       Warn about buffer overflows (older checker)
  alpha.security.ArrayBoundV2     Warn about buffer overflows (newer checker)
  alpha.security.MallocOverflow   Check for overflows in the arguments to malloc()
  alpha.security.ReturnPtrRange   Check for an out-of-bound pointer being returned to callers
  ...
  core.CallAndMessage             Check for logical errors for function calls and Objective-C message expressions (e.g., uninitialized arguments, null function pointers)
  core.DivideZero                 Check for division by zero
  core.DynamicTypePropagation     Generate dynamic type information
  core.NonNullParamChecker        Check for null pointers passed as arguments to a function whose arguments are references or marked with the 'nonnull' attribute
  core.NullDereference            Check for dereferences of null pointers
  core.StackAddressEscape         Check that addresses to stack memory do not escape the function
  ...
  unix.API                        Check calls to various UNIX/Posix functions
  unix.Malloc                     Check for memory leaks, double free, and use-after-free problems. Traces memory managed by malloc()/free().
  unix.MallocSizeof               Check for dubious malloc arguments involving sizeof
  unix.MismatchedDeallocator      Check for mismatched deallocators.
  unix.cstring.BadSizeArg         Check the size argument passed into C string functions for common erroneous patterns
  unix.cstring.NullArg            Check for null pointers being passed as arguments to C string functions
```

在使用 `-enable-checker` 或者 `-disable-checker` 时，不需要完整的指定某个 checker 的名称，
也可以是某一类的，如：    
```shell
$ scan-build -enable-checker alpha ...
$ scan-build -enable-checker alpha.security ...
```

相比 cppcheck，它提供了更多的检查规则。
