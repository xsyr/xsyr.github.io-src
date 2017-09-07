---
layout: post
title: "使用 memusage 统计内存使用情况"
date: 2013-10-09 23:30
categories: 编程
---

glibc 自带了一个 libmemusage 的库，用于收集应用程序运行时的内存使用情况。使用起来
很简单，只要在编译的时候添加 **-lmemusage** 即可。它使用 api hook 技术对 malloc，
realloc，calloc和free 的调用进行监视，统计相应大小内存块的使用比率，并可给出简单
的内存申请与释放的统计信息，可以用于简单的判断时候有内存泄漏。   


### 简单的例子 ###

```cpp
#include <stdlib.h>

#include <memory>

struct GlobalAlloc {
  void *p;
  GlobalAlloc() {
    p = malloc(1024);
  }

  ~GlobalAlloc() {
    free(p);
  }
};

GlobalAlloc g;

int main(int argc, char *argv[])
{
  (void)argc;
  (void)argv;


  char *array = new char[4096];

  (void)array;

  std::unique_ptr<char[]> pchar(new char[512]);

  return 0;
}
```

在 bash 运行之后会打印出程序的内存使用情况。
```bash
$ g++ -g main.cpp -o app
$ ./app
```

![use-memusage](/assets/img/use-memusage.png)


统计信息列出函数调用的次数，每个函数分配的内存总量，调用失败的次数，以及
释放的次数和释放总量。例子中总共调用三次 malloc，其中两次通过 new 操作符号
间接调用，泄漏的内存量为 4096B，与结果相吻合。   
最下面的柱状图显示了各种内存块大小的使用比率。
