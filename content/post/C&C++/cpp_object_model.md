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

&emsp;&emsp;一个虚类对象的内存布局如图所示，首位置需要增加一个“指向虚函数表的指针”。《深度探索 C++ 对象模型》中说虚表指针可放在对象任何位置，实际中不是在头就是在尾，如今主流的编译器似乎都放在对象开头位置。
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

&emsp;&emsp;B 类的虚表结构如下，比较简单，不另外附图说明。

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

&emsp;&emsp;虚表中将父类 A 的 A::A1 重写（override）成了 B::A1，也存放着继承自 A 的虚函数 A::A2，最后还有新增的 B::B1 和 B::B2。

&emsp;&emsp;当一个`A* pa`调用`pa->A1()`时，编译器并不知道 pa 具体指向了哪个对象类型，可能指向 A，也可能指向 B。但能够确定的是，A::A1 和 B::A1 在各自虚表中的偏移位置（这里都是 0）是相等的。在运行时，pa 能够确定指向的类型到底是 A 还是 B，并能找到相应的 vptr，再通过这个偏移位置，最终能调用相应的函数，这就是所谓的“运行时多态”。

### 多重继承

&emsp;&emsp;多重继承与单继承很相似，子类在父类的基础上添加成员和更新虚表，孙子类在子类基础上添加成员和更新虚表，不多解释。

### 多继承
