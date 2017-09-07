---
layout: post
title: "TCLAP - templatized c++ command line parser library"
date: 2013-10-07 21:44
categories: 编程
---

最近写个小程序，需要解析命令好选项，找了好多 option Parser，对比
**getopt**,
[gflags](http://code.google.com/p/gflags/), [anyoption](http://www.hackorama.com/anyoption/),
[option-parser](https://github.com/weisslj/cpp-optparse), [optionparser-cpp](https://gitorious.org/optionparser-cpp#more),
[ArgvParser](http://mih.voxindeserto.de/argvparser.html#example),
[TCLAP](http://tclap.sourceforge.net/)，最终选择了TCLAP，它提供的基于模板的实现，
简单灵活的接口比其他的 parser 更好用更容易扩展。此文为官方文档的精简版，方便以后
查阅。来个 demo 粉墨登场：  

<!-- more -->

```cpp

#include <string>
#include <iostream>
#include <algorithm>
#include <tclap/CmdLine.h>

int main(int argc, char** argv)
{

    // Wrap everything in a try block.  Do this every time,
    // because exceptions will be thrown for problems.
    try {  

        // Define the command line object, and insert a message
        // that describes the program. The "Command description message"
        // is printed last in the help text. The second argument is the
        // delimiter (usually space) and the last one is the version number.
        // The CmdLine object parses the argv array based on the Arg objects
        // that it contains.
        TCLAP::CmdLine cmd("Command description message", ' ', "0.9");

        // Define a value argument and add it to the command line.
        // A value arg defines a flag and a type of value that it expects,
        // such as "-n Bishop".
        TCLAP::ValueArg<std::string> nameArg("n","name","Name to print",true,"homer","string");

        // Add the argument nameArg to the CmdLine object. The CmdLine object
        // uses this Arg to parse the command line.
        cmd.add( nameArg );

        // Define a switch and add it to the command line.
        // A switch arg is a boolean argument and only defines a flag that
        // indicates true or false.  In this example the SwitchArg adds itself
        // to the CmdLine object as part of the constructor.  This eliminates
        // the need to call the cmd.add() method.  All args have support in
        // their constructors to add themselves directly to the CmdLine object.
        // It doesn't matter which idiom you choose, they accomplish the same thing.
        TCLAP::SwitchArg reverseSwitch("r","reverse","Print name backwards", cmd, false);

        // Parse the argv array.
        cmd.parse( argc, argv );

        // Get the value parsed by each arg.
        std::string name = nameArg.getValue();
        bool reverseName = reverseSwitch.getValue();

        // Do what you intend.
        if ( reverseName )
        {
            std::reverse(name.begin(),name.end());
            std::cout << "My name (spelled backwards) is: " << name << std::endl;
        }
        else
        {
            std::cout << "My name is: " << name << std::endl;
        }
    }
    catch (TCLAP::ArgException &e)  // catch any exceptions
    {
        std::cerr << "error: " << e.error() << " for arg " << e.argId() << std::endl; }
    }

```

TCLAP 在头文件中实现，所以只需要引用 `c++ #include <tclap/CmdLine.h>`编译时使用
 **-I** 选项添加头文件的路径。

1. 创建 CmdLine 对象，提供简单的描述信息和版本信息。
2. 创建需要的 option(如 ValueArg)并添加到 CmdLine对象中。或者在实例化 option时
将 CmdLine当作参数传递到 option的构造函数中。两者等价。
3. CmdLine.parse 在解析 option对应的值时可能会抛出异常，所以必须放在 try 语句块中。
4. 调用对应 option 的 getValue 方法获得解析后的值。
5. 每种具名的 option 的构造函数都支持 短名(第一个参数)和长名(第二个参数)，
并可提供描述信息和指定是否强制需要的，还可以提供默认值。

具体的 API 详见[参考手册](http://tclap.sourceforge.net/html/annotated.html)。

------


## 支持的 option 类型 ##

### 1. SwitchArg ###

具名的类型，是一种开关类型，它的 getValue 返回的是 boolean 类型。

### 2. ValueArg ###

顾名思义，这是一种 **option=value** 的类型，比如 -o ./output.txt 或者 --output=
./output.xml等。它是一个模板类 **ValueArg\<T> ** ，可以制定任意类型作为模板的参数，这种类型必须提供
 **operator>>** 操作符，如果在解析命令行时这个操作符无法识别传递进去的字符串则抛出异常。
默认支持 int, foat, double , string等内置类型。

### 3. MultiArg ###

MultiArg 也是一个模板类 ** MultiArg\<T> ** ，支持多个值的 ValueArg(如 gcc 的编译选项中的 **-I** 参数可以指定多个头文件的
搜索路径一下样)，它的 getValue 方法会返回 **std::vector\<T>** 。

### 4. MultiSwitchArg ###

MultiSwitchArg 类似 SwitchArg，但它的 getValue 不是返回 boolean，而是返回这个选项在命令行
中出现的次数 ( 如 -v ， -vv 或者 -vvv )。它也可以提供默认值。

### 5. UnlabeledValueArg ###

UnlabeledValueArg\<T> 其实就是 getopt 中的 参数，它也是一个模板类。例如：
```bash
$ ./app -o ouput -i input 123  45.6  abcd
```

上面的 123， 45.6 和 abcd 分别对应的是 UnlabeledValueArg\<int>,
UnlabeledValueArg\<float> 和 UnlabeledValueArg\<std::string> 。它们被解析的顺序
和它们出现在命令行中的顺序一样，如果将 abcd 放在 123 的前面会导致解析异常。

### 6. UnlabeledMultiArg ###

UnlabeledMultiArg\<T> 是一个模板类，它在程序中只能出现一次，因为它就是那些除了已经被解析
为 UnlabeledValueArg 所剩下的参数，直到遇到 **--** 标识。而且这些参数必须能够被
解析为对应的模板类型，如 UnlabeledMultiArg\<int> 则要求这些参数必须能够解析成
整型。它的 getValue 返回 **std::vector\<T>**

```bash
$ ./app -o ouput -i input 123  45.6  abcd arg1 arg2 arg3
```

上面的 arg1, arg2 和 arg3就被解析为 UnlabeledMultiArg\<std::string>。


------

## 特殊需求 ##

### 1. 多个参数只能指定其中一个 ###

例如，想让 file 和 url 选项二选一：

```cpp
ValueArg<string>  fileArg("f","file","File name to read",true,"/dev/null", "filename");
ValueArg<string>  urlArg("u","url","URL to load",true, "http://example.com", "URL");

cmd.xorAdd( fileArg, urlArg );
cmd.parse(argc, argv);
```

然后就可以通过 fileArg 和 urlArg 的 isSet() 检查到底是哪个选项被设置了。

它可以多于两个 option并且是不同类型的 option：   

```cpp
SwitchArg  stdinArg("s", "stdin", "Read from STDIN", false);
ValueArg<string>  fileArg("f","file","File name to read",true,"/dev/null", "filename");
ValueArg<string>  urlArg("u","url","URL to load",true, "http://example.com", "URL");

vector<Arg*>  xorlist;
xorlist.push_back(&stdinArg);
xorlist.push_back(&fileArg);
xorlist.push_back(&urlArg);

cmd.xorAdd( xorlist );
```

### 2. 只支持长名的option ###

只要在 option 的构造函数的短名参数中复制空串("")即可：
```cpp
ValueArg<string>  fileArg("","file","File name",true,"homer","filename");

SwitchArg  caseSwitch("","upperCase","Print in upper case",false);
```

### 3. 为 ValueArg 指定枚举值 ###
```cpp
vector<string> allowed;
allowed.push_back("homer");
allowed.push_back("marge");
allowed.push_back("bart");
allowed.push_back("lisa");
allowed.push_back("maggie");
ValuesConstraint<string> allowedVals( allowed );

ValueArg<string> nameArg("n","name","Name to print",true,"homer",&allowedVals);
cmd.add( nameArg );
```

如果 ValuesConstrant 不满足需求，可以自己实现 Constraint\<T> 接口。

### 4. 为 整型option 指定 十六进制的值 ###

在 `c++ #include <tclap/CmdLine.h>` 前定义 TCLAP_SETBASE_ZERO
宏。

```cpp
#define TCLAP_SETBASE_ZERO 1

#include <tclap/CmdLine.h>
```
