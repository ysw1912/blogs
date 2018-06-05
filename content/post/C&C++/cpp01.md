---
author: "ysw1912"
date: 2018-06-05
title: "const和static"
tags: [
    "C/C++"
]
categories: [
    "C/C++"
]
---

### class中的const和static

- const 数据成员
  1. 对于类的某个对象是不可变常量
  2. 超出其作用域后会释放空间
  3. <font color=#ff0000>C++11之前 </font>必须在构造函数初始化列表中初始化  
     <font color=#ff0000>C++11开始 </font>除了**static、非 const 类型**，其他类型的数据成员都能在定义时初始化  
     但不论哪种方式，<font color=#ff0000>const 数据成员必须在对象构造函数体之前初始化！</font>

- static 数据成员
  1. 属于类，不依赖于对象，<font color=#ff0000>不占用对象的内存空间</font>，该类的所有对象共享这个成员
  2. 全局作用域，不会释放空间
  3. <font color=#ff0000>必须在全局范围进行初始化</font>，使用 “类型名 类名::变量名 = xxx” 的形式，不能有 static 限定符
  4. 对于 static const 成员或 const static 成员，既可以在定义时初始化，也可以在类外初始化（需要 const，不能有 static），但不能在构造函数初始化列表中初始化

- const 成员函数
  1. 可以访问所有数据成员
  2. 不能改变数据成员的值，<font color=#ff0000>可以改变 static 数据成员的值</font>（static 成员属于类）

- static 成员函数
  1. 只能访问 static 数据成员或者 static 成员函数

- const对象
  1. const 对象只能调用 const 成员函数（只能做 const 成员函数能做的事）
