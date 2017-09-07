---
layout: post
title: "singleton pattern in c++"
date: 2013-11-02 22:39
comments: true
categories: 编程 C/C++
---

## 特点 ##

1. 延迟实例化
1. 多线程安全
2. 使用 C++11 新特性（final, std::call_once )
3. 因为使用到 std::call_once ，所以链接时必须添加 -pthread
4. 不能在由 main 函数引导的流程之外的地方调用 Instance() 函数
5. 使用前必须在 源文件 中调用 INIT_SINGLETON_CLEANER 初始化单实例的 ‘清洁工’。
    单实例模式可以使用静态实例的方式实现，但这样做无法实现 延迟实例化 的需求。
    单实例的生命周期通常和应用程序的周期一致，但是为了能让 内存泄漏检测工具 正确
    地检测到内存泄漏，所以必须要做好收尾工作。（如果是使用 Valgrind 的话可以不用
    清理）

<!-- more -->

include_code singleton.hpp

## 例子 ##

{% raw %}
``` cpp
#include <stdlib.h>

#include <iostream>
#include <memory>
#include <vector>

#include "singleton.hpp"

/// 单实例必须是 final 类，否则使用时会出现异常。
class Sth final : public infra::Singleton<Sth> {
 public:
  void Do() {
    std::cout << "Doing ...." << std::endl;
  }

 /// 应该将构造函数和析构函数隐藏起来，
 /// 防止无意中又创建了其他实例。
 private:
  Sth() {
    /// ...
    std::cout << "Hi" << std::endl;
  }

  ~Sth() {
    /// ...
    std::cout << "Bye" << std::endl;
  }

  /// 因为析构函数已经隐藏起来了，而收尾工作需要调用析构函数
  friend infra::Singleton<Sth>;
};

/// 必须的，因为需要做收尾工作
INIT_SINGLETON_CLEANER;

int main(int argc, char *argv[])
{
  (void)argc;
  (void)argv;

  Sth::Instance().Do();

  return 0;
}
```
{% endraw %}
