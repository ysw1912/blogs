---
author: "ysw1912"
date: 2018-06-15T10:00:00+08:00
lastmod: 2018-06-15T14:56:00+08:00
title: "stringstream 类型转换"
tags: [
    "C/C++"
]
categories: [
    "C/C++"
]
---

## sprintf()

&emsp;&emsp;使用`stdio.h`的`sprintf()`可以实现数据的类型转换。

```cpp
char s[5];
memset(s, 0, sizeof(s));
double d = 3.14;
sprintf(s, "%f", d);
cout << s << endl;	// print "3.140000"
```

&emsp;&emsp;使用 sprintf() 经常会出现 2 个问题：

1. 缓冲区溢出

2. 格式符

## stringstream

&emsp;&emsp;使用 C++ 标准库的`<sstream>`提供的`stringstream`对象可以简化类型转换。

- 转换结果保存在 stringstream 对象的内部缓冲区，不必担心缓冲区溢出。
- 传入参数和目标对象的类型能被自动推导出来，不需要考虑格式化符，可以实现任意类型的转换，而这一点是使用`sprintf()`或`atoi()`等是很难做到的。

&emsp;&emsp;在多次转换中可以重复使用同一个 stringstream 对象，避免多次的对象构造和析构，但要记得每次转换前使用`clear()`。

&emsp;&emsp;如以下函数可以实现 R 类型对象到 L 类型对象的转化。

```cpp
template <class L, class R>
void convert(L& left, const R& right)
{
  stringstream ss;
  if (!(ss << right))	// 向流中传值
    return;
  ss >> left;		// 将流中的值写入到left
}
...
const char* cstr = "3.14159";
double d;
convert(d, cstr);
cout << d << endl;	// print "3.14159"
```

&emsp;&emsp;但同时有个问题，例如从`int`到`long`类型的转换，可以直接使用`operator=`进行赋值，这样反而把问题变复杂了，因此需要判断出这样的情况。

&emsp;&emsp;下面通过模板的类型推导和重载函数的不同返回值，可以确定 R 类型是否能转换到 L 类型，而且这在编译期就完成了判断。

```cpp
template <class L, class R>
struct can_convert
{
  // test()的两个重载
  static int64_t test(L);	// 指定类型L
  static int8_t test(...);	// 变参
  static R getR();
  enum { value = (sizeof(test(getR())) == sizeof(int64_t)) };
};
...
cout << can_convert<int, long>::value << endl;		// print "1"
cout << can_convert<int, string>::value << endl;	// print "0"
```

&emsp;&emsp;但改成下面这样会无法通过编译，因为`if...else...`是运行期的分发，我们需要解决编译期的分发。

```cpp
template <class L, class R>
void convert(L& left, const R& right)
{
  if (can_convert<L, R>::value)
    left = right;
  else {
    stringstream ss;
    if (!(ss << right))
      return;
    ss >> left;
  }
}
...
// error: cannot convert ‘const char* const’ to ‘double’ in assignment
//        left = right;
convert(d, cstr);	
```

&emsp;&emsp;可以使用 bool 模板来进行编译期的分发。

```cpp
template <bool>
struct convert_dispatch 
{
  template <class L, class R>
  static void dispatch(L& left, const R& right)
  { left = right; }
};

template <>
struct convert_dispatch<false> 
{
  template <class L, class R>
  static void dispatch(L& left, const R& right)
  {
    std::stringstream ss;
    if (!(ss << right)) return;
    ss >> left;
  }
};

template <class L, class R>
void convert(L& left, const R& right)
{
  convert_dispatch<can_convert<L, R>::value>::dispatch(left, right);
}
```

## boost::lexical_cast<>()

&emsp;&emsp;`boost`里的`lexical_cast`的内部实现也是`stringstream`，并且若转换失败，会抛出`bad_lexical_cast`异常。

