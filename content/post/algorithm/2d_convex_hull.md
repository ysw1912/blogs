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

### 凸包问题

&emsp;&emsp;凸包（Convex Hull）是一个计算几何（图形学）中的概念。点集Q的凸包是指一个最小凸多边形，满足Q中的点或者在多边形边上或者在其内。
<div align=center>![](/image/post/algorithm/2d_convex_hull/00.jpg)</div>

&emsp;&emsp;正式讨论凸包问题之前，这里先引入一些辅助概念。

### 有序点的方向

&emsp;&emsp;一个平面内有序点的方向（Orientation）可以有三种：

- 逆时针 CounterClockwise
- 顺时针 Clockwise
- 共线 Colinear
<div align=center>![](/image/post/algorithm/2d_convex_hull/01.png)</div>

&emsp;&emsp;对于点a($x_1, y_1$)、b($x_2, y_2$)、c($x_3, y_3$)，线段ab的斜率为
$$ \sigma = \frac{y_2 - y_1}{x_2 - x_1}, $$
线段bc的斜率为
$$ \tau = \frac{y_3 - y_2}{x_3 - x_2}. $$

- 若$ \sigma < \tau $，方向是逆时针（向左转）
- 若σ < τ，方向是共线
- 若σ < τ，方向是顺时针（向右转）

&emsp;&emsp;因此，三个有序点的方向依赖于表达式
$$ (y_2 - y_1) \times (x_3 - x_2) - (y_3 - y_2) \times (x_2 - x_1) $$

