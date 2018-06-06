---
author: "ysw1912"
date: 2018-06-05T10:00:00+08:00
lastmod: 2018-06-06T11:42:00+08:00
title: "const和static"
tags: [
    "C/C++"
]
categories: [
    "C/C++"
]
---

### pointer与const

```cpp
char s[] = "Hello";
const char* p = s;		// 非const指针，const数据（底层const：星号左边）
char const* p = s;		// 同上，const也可以写在类型之后
char* const p = s;		// const指针，非const数据（顶层const：星号右边）
const char* const p = s;	// const指针，const数据
```

STL迭代器作用类似于T*指针
```cpp
const std::vector<int>::iterator it = vec.begin();	// it类似于T* const
std::vector<int>::const_iterator it = vec.begin();	// it类似于const T*
```


### class中的const和static

- const 数据成员
  1. 对于类的某个对象是不可变常量。
  2. 超出其作用域后会释放空间。
  3. <font color=#ff0000>C++11之前 </font>必须在构造函数初始化列表中初始化；  
     <font color=#ff0000>C++11开始 </font>除了**static、非 const 类型**，其他类型的数据成员都能在定义时初始化。  
     但不论哪种方式，<font color=#ff0000>const 数据成员必须在对象构造函数体之前初始化！</font>

- static 数据成员
  1. 属于类，不依赖于对象，<font color=#ff0000>不占用对象的内存空间</font>，该类的所有对象共享这个成员。
  2. 全局作用域，不会释放空间。
  3. <font color=#ff0000>必须在全局范围进行初始化</font>，使用 “类型名 类名::变量名 = xxx” 的形式，不能有 static 限定符。
  4. 对于 static const 成员或 const static 成员，既可以在定义时初始化，也可以在类外初始化（需要 const，不能有 static），但不能在构造函数初始化列表中初始化。

- const 成员函数
  1. 可以访问所有数据成员。
  2. 不能改变数据成员的值，<font color=#ff0000>可以改变 static 数据成员的值</font>（static 成员属于类）。  
     <font color=#ff0000>mutable 关键字</font>可以释放掉 non-static 数据成员的 bitwise constness 约束，const 成员函数可以修改 mutable 成员的值，例如可将一个记录函数调用次数的计数器变量修饰为 mutable。
  3. 两个成员函数如果只是常量性不同，可以被<font color=#ff0000>重载</font>。  
     非const对象会调用非const版本的函数重载，const对象会调用const版本的函数重载。

- static 成员函数
  1. 只能访问 static 数据成员或者 static 成员函数。

- const对象
  1. const 对象只能调用 const 成员函数（只能做 const 成员函数能做的事）。
