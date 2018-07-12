---
author: "ysw1912"
date: 2018-06-05T10:00:00+08:00
lastmod: 2018-07-05T12:50:00+08:00
title: "Effective C++ 笔记"
tags: [
    "C/C++"
]
categories: [
    "C/C++"
]
---

### 条款2：尽量以 const，enum，inline 替换 #define

- 对于单纯常量，尽量以`const`对象或`enum`替换`#define`。
  - `enum`是一个右值，无法被取地址，可以充当`int`常量。
- 对于类似函数的宏，最好改用`inline`函数替换`#define`。
  - `#define`函数宏的缺点：

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
-----

## 构造/析构/赋值运算

### 条款5：编译期自动为 class 生成哪些函数

- 如果没有声明，编译器可以暗自为 class 创建 default 构造函数、copy 构造函数、copy 赋值操作符、析构函数。
- 编译器拒绝为 class 产生 copy 赋值操作符`operator=`的三种情况：
  1. class 内含 reference 成员，因为 C++ 不允许引用改指向不同对象。
  2. class 内含 const 成员。
  3. 基类将 copy 赋值操作符声明为`private`，因为继承类无权调用该成员函数。

### 条款6：阻止编译器自动生成拷贝构造和拷贝赋值

- 将 copy constructor 或者 copy assignment operator 声明为`private`。
- 为防止成员函数和友元函数调用`private`函数，可以只声明而不去定义它们，这将会产生一个<font color=#ff0000>链接错误</font>。
- 为将链接期错误移至编译期，可将 copy 动作设计在基类中。

```cpp
class Uncopyable {
 protected:
  Uncopyable() {}
  ~Uncopyable() {}
 private:
  Uncopyable(const Uncopyable&);
  Uncopyable& operator=(const Uncopyable&);
};

class A : private Uncopyable {
  ...
};
```

### 条款7：为多态基类声明 virtual 析构函数

- 当派生类对象通过基类指针被`delete`，而基类的析构函数并未声明为`virtual`，通常导致该对象的<font color=#ff0000>派生成分没被销毁</font>。
- “任何带有`virtual`函数的类”以及“具有多态性质的基类”几乎<font color=#ff0000>必须</font>有`virtual`析构函数。
- 若类不含`virtual`函数，通常表示它并不适合做一个基类。当类不企图被当做基类，也不适合令其析构函数为`virtual`。

### 条款8：不鼓励在析构函数中抛异常

- 若析构函数可能抛出异常，应当`try`+`catch`捕捉异常，但吞下它（并不`throw`）或强制结束（调用`std::abort()`）。
- 若某操作抛出的异常必须被处理，则 class 应当提供普通函数（而非析构函数）处理。

### 条款9：绝不在构造和析构函数中调用虚函数

- 构造 derived class 对象时，base class 对象会率先构造，而在基类对象构造期间，virtual 函数不具备多态性。使派生类对象构造时，调用虚函数的基类版本。
- 若该虚函数是 pure virtual，代码甚至无法链接。

-----

## 资源管理

智能指针与 RAII 不在此记录。

&emsp;

-----

## 设计与声明

### 条款21：返回对象时不要试图返回 reference

### 条款24：若所有参数皆需类型转换，采用 non-member 函数

&emsp;&emsp;例如对于有理数类 Rational，一个计算乘积的函数`operator*()`，合理的声明应为`const Rational operator*(const Rational&, const Rational&)`。

- 条款21：直接返回对象的拷贝，其构造成本和析构成本是值得的。
  - 若返回 local stack 对象的指针或引用，该对象在函数退出时就已被销毁了。
  - 若返回 local static 对象，在需要多个这样的返回对象时，就有问题。
  - 若返回 heap-allocated 对象的指针或引用，很多时候无法进行 delete，导致内存泄漏，如下面的情况。

  ```cpp
Rational w, x, y, z;
w = x * y * z;	// operator*(operator*(x, y), z)
  ```

- 条款24：
  - 若声明为 member 函数`const Rational operator*(const Rational&) const`，会出现如下错误。

```cpp
Rational w, x;
w = x * 2;    // 正确
w = 2 * x;    // 错误
```

### 条款25：swap 函数

- 当`std::swap`对自定义 class 效率不高时，需自己写一个 swap 的成员函数，并确保其不抛出异常。
- 如果有了 member swap，也应当在该 class 所属的 namespace 里提供一个 non-member swap 来调用前者。
- 对于 class（而非 class template），需全特化一个 std::swap 版本。
- 调用 swap 时，你的 T 类型对象调用 T 专属版本，若不存在则调用 std 版本。

```cpp
template <class T>
void do_something(T& obj1, T& obj2)
{
  using std::swap;    // 令std::swap在此函数内可用
  ...
  swap(obj1, obj2);    // 调用最佳swap版本
  ...
}
```

-----

## 实现


