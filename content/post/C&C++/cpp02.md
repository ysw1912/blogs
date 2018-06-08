---
author: "ysw1912"
date: 2018-06-05T10:00:00+08:00
lastmod: 2018-06-08T11:37:00+08:00
title: "Effective C++ 笔记"
tags: [
    "C/C++"
]
categories: [
    "C/C++"
]
---

### 条款2：尽量以 const，enum，inline 替换 #define

- 对于单纯常量，尽量以const对象或enums替换#define。
  - enum是一个右值，无法被取地址，可以充当 int 常量。
- 对于类似函数的宏macros，最好改用inline函数替换#define。
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

### 条款3：尽可能使用 const

- 令函数返回常量值，可预防因客户错误而造成的意外。

```cpp
// 有理数类
class Rational { ... };
const Rational operator*(const Rational& lhs, const Rational& rhs);

Rational a, b, c;
...
if (a * b = c) ...	// 其实想做比较动作，结果进行赋值
```

- 当 const 和 non-const 成员函数有等价的实现时，令 non-const 版本调用 const 版本可避免代码重复。

```cpp
class TextBlock {
 public:
  ...
  const char& operator[](size_t pos) const {	// const成员函数
    ...		// 边界检验
    ...		// log数据访问
    ...		// 检验数据完整性
    return text[pos];
  }

  char& operator[](size_t pos) {
    return const_cast<char&>(			// 将op[]返回值的const移除
      static_cast<const TextBlock&>(*this)	// 为*this加上const
        [pos]					// 调用const operator[]
    );
  }
  ...
 private:
  std::string text;
};
```

### 条款5：了解 C++ 默默编写并调用哪些函数

- 如果没有声明，编译器可以暗自为 class 创建 default 构造函数、copy 构造函数、copy 赋值操作符、析构函数。
- 编译器拒绝为 class 产生 copy 赋值操作符`operator=`的三种情况：
  1. class 内含 reference 成员，因为 C++ 不允许引用改指向不同对象。
  2. class 内含 const 成员。
  3. 基类将 copy 赋值操作符声明为`private`，因为继承类无权调用该成员函数。

