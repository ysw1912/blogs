---
author: "ysw1912"
date: 2019-07-11T09:00:00+08:00
lastmod: 2019-09-07T22:00:00+08:00
title: "GFlags使用"
tags: [
    "C/C++"
]
categories: [
    "C/C++"
]
---

## GFlags

&emsp;&emsp;GFlags 是 Google 开源的一个命令行 flag 库。与 getopt 之类不同，flag 的定义可以散布在各个源码中，而不用放在一起。一个源码文件可以定义一些它自己的flag，链接了该文件的应用都能使用这些flag，这样就能方便地复用代码。但要注意，如果不同的文件定义了相同的 flag，链接时会报错。

&emsp;&emsp;样例代码参见 [GitHub/Cpp-Practice-Test/gflags_test](https://github.com/ysw1912/Cpp-Practice-Test/tree/master/gflags_test)

-----

#### 定义 Flag

&emsp;&emsp;使用 gflags 需要包含头文件`#include <gflags/gflags.h>`，支持的类型有：

- `DEFINE_bool`: boolean
- `DEFINE_int32`: 32-bit integer
- `DEFINE_int64`: 64-bit integer
- `DEFINE_uint64`: unsigned 64-bit integer
- `DEFINE_double`: double
- `DEFINE_string`: C++ string

该宏的三个参数分别代表命令行参数名，参数默认值，参数的帮助信息。

&emsp;&emsp;gflags 不支持列表，但可以借助 string 实现。

&emsp;&emsp;在头文件使用`DECLARE_type`声明 flag，在对应源文件使用`DEFINE_type`定义，则 include 头文件后即可使用。

#### 使用 Flag

&emsp;&emsp;定义的 flag 可以像正常的变量一样使用，只需在前面加上`FLAGS_`前缀。

#### 验证 Flag

&emsp;&emsp;DEFINE 一个 flag 后，可以给其注册一个验证函数。

&emsp;&emsp;宏`DEFINE_validator`调用函数`RegisterFlagValidator()`，并返回注册是否成功。

&emsp;&emsp;如果`ParseCommandLineFlags()`时参数不合法，则报错。

#### 改变 Flag 默认值

&emsp;&emsp;只需要在调用`ParseCommandLineFlags()`之前将 flag 赋值为需要的默认值即可。

&emsp;&emsp;或者使用`SetCommandLineOption(const char* name, const char* value)`将 value 对应的值赋给 FLAGS_name。

