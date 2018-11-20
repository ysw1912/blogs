---
author: "ysw1912"
date: 2018-11-20T11:00:00+08:00
lastmod: 2018-11-20T11:00:00+08:00
title: "2D凸包问题"
tags: [
    "算法"
]
categories: [
    "算法"
]

---


<script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.1/MathJax.js?config=TeX-AMS-MML_HTMLorMML">
</script>
<script type="text/x-mathjax-config">
  MathJax.Hub.Config({
    tex2jax: {
      inlineMath: [ ['$','$'], ["\\(","\\)"] ],
      processEscapes: true
    }
  });
</script>
<script type="text/javascript" src="path-to-MathJax/MathJax.js?config=TeX-AMS_HTML">
</script>

## 凸包

&emsp;&emsp;凸包（Convex Hull）是一个计算几何（图形学）中的概念。点集Q的凸包是指一个最小凸多边形，满足Q中的点或者在多边形边上或者在其内。
<div align=center>![](/image/post/algorithm/2d_convex_hull/00.jpg)</div>

&emsp;&emsp;正式讨论凸包问题之前，这里先引入一些辅助概念。

#### 有序点的方向

&emsp;&emsp;一个平面内有序点的方向（Orientation）可以有三种：

- 逆时针 CounterClockwise
- 顺时针 Clockwise
- 共线 Colinear
<div align=center>![](/image/post/algorithm/2d_convex_hull/01.png)</div>

&emsp;&emsp;对于点$a(x_1, y_1)$、$b(x_2, y_2)$、$c(x_3, y_3)$，线段$ab$的斜率为
$$ \sigma = \frac{y_2 - y_1}{x_2 - x_1} $$
线段$bc$的斜率为
$$ \tau = \frac{y_3 - y_2}{x_3 - x_2} $$

- 若$ \sigma < \tau $，方向是逆时针（向左转）
- 若$ \sigma = \tau $，方向是共线
- 若$ \sigma > \tau $，方向是顺时针（向右转）

&emsp;&emsp;因此，三个有序点的方向依赖于表达式
$$ (y_2 - y_1) \times (x_3 - x_2) - (y_3 - y_2) \times (x_2 - x_1) $$

- 若表达式为负，方向是逆时针
- 若表达式为0，方向是共线
- 若表达式为正，方向是顺时针

#### 两线段相交

&emsp;&emsp;利用上述方向的概念，很容易判断两线段<font color=#ff0000> (p1, q1) </font>和<font color=#0000ff> (p2, q2) </font>是否相交。

- 一般情况

&emsp;&emsp;(<font color=#ff0000>p1, q1</font>, <font color=#0000ff>p2</font>) 和 (<font color=#ff0000>p1, q1</font>, <font color=#0000ff>q2</font>) 方向不同并且 (<font color=#0000ff>p2, q2</font>, <font color=#ff0000>p1</font>) 和 (<font color=#0000ff>p2, q2</font>, <font color=#ff0000>q1</font>) 方向不同。
<div align=center>![](/image/post/algorithm/2d_convex_hull/02.png)</div>

- 特殊情况

&emsp;&emsp;(<font color=#ff0000>p1, q1</font>, <font color=#0000ff>p2</font>)、(<font color=#ff0000>p1, q1</font>, <font color=#0000ff>q2</font>)、(<font color=#0000ff>p2, q2</font>, <font color=#ff0000>p1</font>) 和 (<font color=#0000ff>p2, q2</font>, <font color=#ff0000>q1</font>) 4 个方向均共线并且
  - <font color=#ff0000> (p1, q1) </font>和<font color=#0000ff> (p2, q2) </font> 的 x 轴部分相交
  - <font color=#ff0000> (p1, q1) </font>和<font color=#0000ff> (p2, q2) </font> 的 y 轴部分相交
<div align=center>![](/image/post/algorithm/2d_convex_hull/03.png)</div>

## 2D凸包问题

&emsp;&emsp;凸包问题最常见的两种解法是 Jarvis 步进法和 Graham 扫描法，有了上面的基础，这两种方法很容易实现出来。

### Jarvis’s Algorithm or Wrapping

<div align=center>![](/image/post/algorithm/2d_convex_hull/04.png)</div>

1. 初始化 p 为最左侧的点（x 坐标最小的点）
2. 循环如下步骤，直到回到初始的最左侧的点
  1. 找到下一个点 q，使得对于任意其他点 r，有三元组 (p, q, r) 的方向是逆时针
  2. 存储 q 作为 p 的下一个输出元素
  3. p = q

```cpp
void ConvexHull()
{

}
```
&emsp;&emsp;算法的复杂度为 O(m * n)，其中 m 是输出凸包中点的数量，n 是输入点集中点的数量。最坏的情况下，点集中所有点都在输出的凸包上，时间复杂度为 O(n^2)。

### Graham Scan

<div align=center>![](/image/post/algorithm/2d_convex_hull/05.png)</div>
<div align=center>![](/image/post/algorithm/2d_convex_hull/06.png)</div>

```cpp
void ConvexHull()
{

}
```
&emsp;&emsp;算法的复杂度为 O(m * n)，其中 m 是输出凸包中点的数量，n 是输入点集中点的数量。最坏的情况下，点集中所有点都在输出的凸包上，时间复杂度为 O(n^2)。