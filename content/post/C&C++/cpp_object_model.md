---
author: "ysw1912"
date: 2018-07-12T16:00:00+08:00
lastmod: 2018-07-12T16:00:00+08:00
title: "C++ 对象模型"
tags: [
    "C/C++"
]
categories: [
    "C/C++"
]
---

&emsp;&emsp;看《深度探索 C++ 对象模型》这本书后的一些总结，C++ 标准对于对象内存布局貌似比较放任，因此这里指定使用 64 位的 gcc 5.4 编译器进行测试。

## 无多态情况

```cpp
class A
{
public:
    static int a0;
    int a1 = 1;
    int a2 = 2;
};

int A::a0 = 6;

class B : public A
{
public:
    int b1 = 3;
};

int main()
{
    printf("%p\n", &A::a0);	// print "0x601058"
    printf("%p\n", &A::a1);	// print "(nil)"
    printf("%p\n", &A::a2);	// print "0x4"
    printf("%p\n", &B::b1);	// print "0x8"

    B b;
    printf("%d\n", *(int*)((char*)&b + 0));	// print "1"
    printf("%d\n", *(int*)((char*)&b + 4));	// print "2"
    printf("%d\n", *(int*)((char*)&b + 8));	// print "3"
    return 0;
}
```

&emsp;&emsp;由 19 行知道，static 数据成员并不内含于对象之中，而是被视为一个全局变量，之后不作考虑。

&emsp;&emsp;而第 20 — 22 行会有编译警告`warning: format '%p' expects argument of type 'void*', but argument 2 has type 'int A::*'`，但并不影响结果。这里使用的是“指向数据成员的指针”，类型为`int A::*`，且无法转换为`void*`，获取到的是数据成员在类对象中的偏移。《深度探索 C++ 对象模型》中说这个偏移要 +1，但显然如今的编译器不需要。

PS：指向成员函数的指针的声明为`函数返回类型 (类名::*指针名)(参数列表);`，这里不作介绍。

&emsp;&emsp;因此一个无多态的继承类的内存布局是父类 A 的成员，再加上子类 B 的成员。

PS：这里只用`int`测试，不考虑[内存对齐](https://www.baidu.com)。

## 多态情况

### virtual class

```cpp
class A
{
public:
    int a1;
    int a2;
    virtual void A1() { printf("A::A1()\n"); }
    virtual void A2() { printf("A::A2()\n"); }
};

int main()
{
    printf("%p\n", &A::a1);
    printf("%p\n", &A::a2);

    A a;
    typedef void (*PF)();   // 函数指针
    PF pf = nullptr;
    for (int i = 0; i < 2; ++i) {
        pf = (PF)*((long*)*(long*)&a + i);
        pf();
    };
    return 0;
}
```

&emsp;&emsp;输出结果是

```
0x8
0xc    // 12
A::A1()
A::A2()
```

&emsp;&emsp;一个虚类对象 A 的内存布局如图所示，首位置需要增加一个“指向虚函数表的指针”。《深度探索 C++ 对象模型》中说虚表指针可放在对象任何位置，实际中不是在头就是在尾，如今主流的编译器似乎都放在对象开头位置。
<div align=center>![](/image/post/C&C++/cpp_object_model/01.png)</div>

&emsp;&emsp;使用命令`gcc -fdump-class-hierarchy classA.cpp`，可在当前目录下生成一个 classA.cpp.002t.class 文件，内容如下，可以查看该类的虚表结构。由 vptr=((& A::_ZTV1A) + 16u) 可以看出，我们所说的虚表指针指向的是虚表最后的 virtual function pointers 部分，至于之前的部分，之后再详细说明。

```
Vtable for A
A::_ZTV1A: 4u entries
0     (int (*)(...))0
8     (int (*)(...))(& _ZTI1A)
16    (int (*)(...))A::A1
24    (int (*)(...))A::A2

Class A
   size=16 align=8
   base size=16 base align=8
A (0x0x7ff96382f5a0) 0
    vptr=((& A::_ZTV1A) + 16u)
```

### 单一继承

```cpp
class B: public A
{
public:
    int b1;
    virtual void B1() { printf("B::B1()\n"); }
    virtual void B2() { printf("B::B2()\n"); }
    virtual void A1() { printf("B::A1()\n"); }
};

int main()
{
    printf("%p\n", &B::a1);
    printf("%p\n", &B::a2);
    printf("%p\n", &B::b1);

    B b;
    typedef void (*PF)();
    PF pf = nullptr;
    for (int i = 0; i < 4; ++i) {
        pf = (PF)*((long*)*(long*)&b + i);
        pf();
    };
    return 0;
}
```

&emsp;&emsp;输出结果是

```
0x8
0xc     // 12
0x10    // 16
B::A1()
A::A2()
B::B1()
B::B2()
```

&emsp;&emsp;B 类的虚表结构如下

```
Vtable for B
B::_ZTV1B: 6u entries
0     (int (*)(...))0
8     (int (*)(...))(& _ZTI1B)
16    (int (*)(...))B::A1
24    (int (*)(...))A::A2
32    (int (*)(...))B::B1
40    (int (*)(...))B::B2

Class B
   size=24 align=8
   base size=20 base align=8
B (0x0x7feceec1b1a0) 0
    vptr=((& B::_ZTV1B) + 16u)
  A (0x0x7feceed84600) 0
      primary-for B (0x0x7feceec1b1a0)
```

&emsp;&emsp;虚表中将父类 A 的 A::A1 重写（override）成了 B::A1，也存放着继承自 A 的虚函数 A::A2，最后还有新增的 B::B1 和 B::B2，内存布局如图所示。
<div align=center>![](/image/post/C&C++/cpp_object_model/02.png)</div>

&emsp;&emsp;当一个`A* pa`调用`pa->A1()`时，编译器并不知道 pa 具体指向了哪个对象类型，可能指向 A，也可能指向 B。但能够确定的是，A::A1 和 B::A1 在各自虚表中的偏移位置（这里都是 0）是相等的。在运行时，pa 能够确定指向的类型到底是 A 还是 B，并能找到相应的 vptr，再通过这个偏移位置，最终能调用相应的函数，这就是所谓的“运行时多态”。

### 多重继承

&emsp;&emsp;多重继承与单继承很相似，子类在父类的基础上添加成员和更新虚表，孙子类在子类基础上添加成员和更新虚表，不多解释。

### 多继承

&emsp;&emsp;C++支持多继承，即一个子类可同时继承多个父类。

```cpp
class A
{
public:
    int a1;
    int a2;
    virtual void A1() { printf("A::A1()\n"); }
    virtual void A2() { printf("A::A2()\n"); }
};

class B
{
public:
    int b1;
    virtual void B1() { printf("B::B1()\n"); }
    virtual void B2() { printf("B::B2()\n"); }
};

class C : public A, public B
{
public:
    int c1;
    virtual void A1() { printf("C::A1()\n"); }
    virtual void B2() { printf("C::B2()\n"); }
    virtual void C1() { printf("C::C1()\n"); }
};

int main()
{
    printf("%p\n", &C::a1);
    printf("%p\n", &C::a2);
    printf("%p\n", &C::b1);
    printf("%p\n", &C::c1);

    C c;
    typedef void (*PF)();
    PF pf = nullptr;

    printf("A's vptr:\n");
    for (int i = 0; i < 4; ++i) {
        pf = (PF)*((long*)*(long*)&c + i);
        pf();
    };

    long* p = (long*)&c + 2;
    printf("B's vptr:\n");
    for (int i = 0; i < 2; ++i) {
        pf = (PF)*((long*)*(long*)p + i);
        pf();
    }
    return 0;
}
```

&emsp;&emsp;输出结果如下。这里值得注意的是，我本以为 &C::b1 输出结果为 24，因为 b1 相对于对象起始地址的偏移是 24（见下面的内存布局图），结果这里很智能地输出了 8，应该是减去了 C 中 B subobject 的偏移量 16，而这个 -16 也体现在了 C 的虚表里。

```
0x8
0xc     // 12
0x8     // 竟然不是0x18（24）
0x1c    // 28
A's vptr:
C::A1()
A::A2()
C::B2()
C::C1()
B's vptr:
B::B1()
C::B2()
```

&emsp;&emsp;C 类的虚表结构如下

```
Vtable for C
C::_ZTV1C: 10u entries
0     (int (*)(...))0
8     (int (*)(...))(& _ZTI1C)
16    (int (*)(...))C::A1
24    (int (*)(...))A::A2
32    (int (*)(...))C::B2
40    (int (*)(...))C::C1
48    (int (*)(...))-16
56    (int (*)(...))(& _ZTI1C)
64    (int (*)(...))B::B1
72    (int (*)(...))C::_ZThn16_N1C2B2Ev

Class C
   size=32 align=8
   base size=32 base align=8
C (0x0x7fcec84ac2a0) 0
    vptr=((& C::_ZTV1C) + 16u)
  A (0x0x7fcec8603660) 0
      primary-for C (0x0x7fcec84ac2a0)
  B (0x0x7fcec86036c0) 16
      vptr=((& C::_ZTV1C) + 64u)
```

&emsp;&emsp;据此可以知道，当子类继承多个父类，且多个父类都是 virtual class 时，子类对象中将包含多个虚表指针。其中 C 自身与基类 A 共用了同一个虚函数表，因此也称 A 为 C 的主基类 primary base class。
<div align=center>![](/image/post/C&C++/cpp_object_model/03.png)</div>

&emsp;&emsp;由于 C 有 2 个虚表，从上面 .class 文件也可以看出，3 — 8 行是主虚表 primary virtual table，9 — 12 行是次虚表 secondary virtual table。由此可知，虚表除了指向虚函数的地址的指针外，还包含了其他信息。
<div align=center>![](/image/post/C&C++/cpp_object_model/04.png)</div>

&emsp;&emsp;如图所示，一个虚表包含以下几个部分。

1. 最上面 2 个 slot 仅在虚继承时使用，否则不存在。详见虚继承部分。
2. “offset to top”是指到对象起始地址的偏移，单继承或多重继承时为 0，而多继承中，除了第一个基类，其它的基类子对象都相对于起始位置有偏移，均不为 0。
3. “RTTI information”是一个对象指针，用于唯一标识对象的类型。
4. “virtual function pointers”是我们理解的狭义的虚表，即存放虚函数指针的列表。

## 虚继承

```cpp
class A
{
public:
    int a1;
    int a2;
    virtual void A1() { printf("A::A1()\n"); }
    virtual void A2() { printf("A::A2()\n"); }
};

class B : virtual public A
{
public:
    int b1;
    virtual void B1() { printf("B::B1()\n"); }
    virtual void B2() { printf("B::B2()\n"); }
};

int main()
{
    printf("%p\n", &B::a1);
    printf("%p\n", &B::a2);
    printf("%p\n", &B::b1);

    B b;
    typedef void (*PF)();
    PF pf = nullptr;

    printf("B's vptr:\n");
    for (int i = 0; i < 2; ++i) {
        pf = (PF)*((long*)*(long*)&b + i);
        pf();
    };

    long* p = (long*)&b + 2;
    printf("A's vptr:\n");
    for (int i = 0; i < 2; ++i) {
        pf = (PF)*((long*)*(long*)p + i);
        pf();
    }
    return 0;
}
```

&emsp;&emsp;输出结果如下。

```
0x8
0xc     // 12
0x8     // 
B's vptr:
B::B1()
B::B2()
A's vptr:
A::A1()
A::A2()
```

&emsp;&emsp;B 类的虚表结构如下。可以看到，当存在虚继承时，虚表中会用上 virtual base offset 字段，标明该类与虚基类的偏移，结合下面的内存布局来看，B 的虚表中 virtual base offset 为 16，A 自己就是就是虚基类，所以 virtual base offset 为 0。

```
Vtable for B
B::_ZTV1B: 11u entries
0     16u
8     (int (*)(...))0
16    (int (*)(...))(& _ZTI1B)
24    (int (*)(...))B::B1
32    (int (*)(...))B::B2
40    0u
48    0u
56    (int (*)(...))-16
64    (int (*)(...))(& _ZTI1B)
72    (int (*)(...))A::A1
80    (int (*)(...))A::A2

VTT for B
B::_ZTT1B: 2u entries
0     ((& B::_ZTV1B) + 24u)
8     ((& B::_ZTV1B) + 72u)

Class B
   size=32 align=8
   base size=12 base align=8
B (0x0x7fc1865ab1a0) 0
    vptridx=0u vptr=((& B::_ZTV1B) + 24u)
  A (0x0x7fc186714600) 16 virtual
      vptridx=8u vbaseoffset=-24 vptr=((& B::_ZTV1B) + 72u)
```

&emsp;&emsp;B 的对象模型如下。当存在虚基类时，先是子类的成员，最后才是虚基类的成员，而不像普通继承是将基类放在对象起始地址。因此需要用 virtual base offset 找到虚基类。至于为何将虚基类放在最后？是因为虚继承主要用于坑爹的“菱形继承”，让虚基类在派生类中只占用一份内存空间。
<div align=center>![](/image/post/C&C++/cpp_object_model/05.png)</div>
