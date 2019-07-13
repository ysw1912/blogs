---
author: "ysw1912"
date: 2019-07-11T09:00:00+08:00
lastmod: 2019-07-13T17:30:00+08:00
title: "GFlags使用"
tags: [
    "C/C++"
]
categories: [
    "C/C++"
]
---

## GFlags

​    GFlags 是 Google 开源的一个命令行 flag 库。与 getopt 之类不同，flag 的定义可以散布在各个源码中，而不用放在一起。一个源码文件可以定义一些它自己的flag，链接了该文件的应用都能使用这些flag，这样就能方便地复用代码。但要注意，如果不同的文件定义了相同的 flag，链接时会报错。

-----

#### 定义 Flag

​    使用 gflags 需要包含头文件`#include <gflags/gflags.h>`，支持的类型有：
- `DEFINE_bool`: boolean
- `DEFINE_int32`: 32-bit integer
- `DEFINE_int64`: 64-bit integer
- `DEFINE_uint64`: unsigned 64-bit integer
- `DEFINE_double`: double
- `DEFINE_string`: C++ string

该宏的三个参数分别代表命令行参数名，参数默认值，参数的帮助信息。

​    gflags 不支持列表，但可以借助 string 实现。

​    在头文件使用`DECLARE_type`声明 flag，在对应源文件使用`DEFINE_type`定义，则 include 头文件后即可使用。

#### 使用 Flag

​    定义的 flag 可以像正常的变量一样使用，只需在前面加上`FLAGS_`前缀。

#### 验证 Flag

​    DEFINE 一个 flag 后，可以给其注册一个验证函数。

​    宏`DEFINE_validator`调用函数`RegisterFlagValidator()`，并返回注册是否成功。

​    如果`ParseCommandLineFlags()`时参数不合法，则报错。

#### 改变 Flag 默认值

​    只需要在调用`ParseCommandLineFlags()`之前将 flag 赋值为需要的默认值即可。

​    或者使用`SetCommandLineOption(const char* name, const char* value)`将 value 对应的值赋给 FLAGS_name。

-----

### Example Code

*addr.h*
```cpp
#ifndef CPP_ADDR_H_
#define CPP_ADDR_H_

#include <stdint.h>

#include <gflags/gflags.h>

namespace inet {

DECLARE_string(ip);
DECLARE_int32(port);

static bool ValidatePort(const char* flag_name, int32_t value);

}  // namespace inet

#endif //CPP_ADDR_H_
```

*addr.cpp*
```cpp
#include "addr.h"

namespace inet {

DEFINE_string(ip, "127.0.0.1", "connect ip");
DEFINE_int32(port, 80, "listen port");

bool ValidatePort(const char* flag_name, int32_t value) {
  if (value > 0 && value < 32768)
    return true;
  printf("Invalid value for --%s: %d\n", flag_name, value);
  return false;
}

DEFINE_validator(port, &ValidatePort);

}  // namespace inet
```

*main.cpp*
```cpp
#include <iostream>

#include "addr.h"

int main(int argc, char** argv) {
  inet::FLAGS_ip = "255.255.255.255";
  google::SetCommandLineOption("port", "123");

  google::ParseCommandLineFlags(&argc, &argv, true);

  printf("ip: %s\n", inet::FLAGS_ip.c_str());
  printf("port: %d\n", inet::FLAGS_port);

  google::ShutDownCommandLineFlags();
  return 0;
}
```

*CMakeLists.txt*

```shell
project(gflags_test)

set(SOURCE_FILES main.cpp)

set(gflags_DIR D:/workspace/third_party)
find_package(gflags REQUIRED)

add_library(inet_addr
    addr.cpp
)
target_link_libraries(inet_addr gflags)
add_library(inet::addr ALIAS
inet_addr)

add_executable(addr ${SOURCE_FILES})
target_link_libraries(addr
    inet::addr
    gflags
)
```