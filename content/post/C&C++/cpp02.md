---
author: "ysw1912"
date: 2018-06-05
title: "Effective C++ 笔记"
tags: [
    "C/C++"
]
categories: [
    "C/C++"
]
---

### 条款2

- 对于单纯常量，尽量以const对象或enums替换#define
  - enum是一个右值，无法被取地址，可以充当 int 常量
- 对于类似函数的宏macros，最好改用inline函数替换#define
  - #define函数宏的缺点：

```cpp
#define MAX(a, b) ((a) > (b) ? (a) : (b))
...
int a = 5, b = 0;
MAX(++a, b);
cout << a << endl;  // 7，a累加2次
MAX(++a, b + 10);
cout << a << endl;  // 8，a累加1次
```
