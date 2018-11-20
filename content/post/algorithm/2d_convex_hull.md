---
author: "ysw1912"
date: 2018-11-20T11:00:00+08:00
lastmod: 2018-11-20T19:21:00+08:00
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

&emsp;&emsp;正式讨论凸包问题之前，这里先引入一个辅助概念——“方向”。

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

```cpp
struct Point
{
	int x;
    int y;
};

/* -1 逆时针
	0 共线
	1 顺时针 */
int Orientation(const Point& p, const Point& q, const Point& r)
{
	int v = (q.y - p.y) * (r.x - q.x) - (r.y - q.y) * (q.x - p.x);
	return v ? v / abs(v) : v;
}
```

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

```cpp
// 给定p、q、r三点共线，判断q是否在线段pr上
bool OnSegment(const Point& p, const Point& q, const Point& r)
{
	if (q.x <= max(p.x, r.x) && q.x >= min(p.x, r.x) &&
		q.y <= max(p.y, r.y) && q.y >= min(p.y, r.y))
		return true;
	return false;
}

// 判断线段ab与线段cd是否相交
bool Intersect(const Point& a, const Point& b, const Point& c, const Point& d)
{
	int o1 = Orientation(a, b, c);
	int o2 = Orientation(a, b, d);
	int o3 = Orientation(c, d, a);
	int o4 = Orientation(c, d, b);

	if (o1 != o2 && o3 != o4)
		return true;

	// a、b、c共线且c在线段ab上
	if (o1 == 0 && OnSegment(a, c, b)) return true;
	if (o2 == 0 && OnSegment(a, d, b)) return true;
	if (o3 == 0 && OnSegment(c, a, d)) return true;
	if (o4 == 0 && OnSegment(c, b, d)) return true;

	return false;
}
```

## 2D凸包问题

&emsp;&emsp;凸包问题最常见的两种解法是 Jarvis 步进法和 Graham 扫描法，有了上面的基础，这两种方法很容易实现出来。

### Jarvis’s Algorithm or Wrapping

&emsp;&emsp;算法流程如下：

1. 初始化 p 为最左侧的点（x 坐标最小的点）
2. 循环如下步骤，直到回到初始的最左侧的点
  1. 找到下一个点 q，使得对于任意其他点 r，有三元组 (p, q, r) 的方向是逆时针，这里就要用到上面方向的概念
  2. 存储 q 作为 p 的下一个输出元素
  3. p = q
<div align=center>![](/image/post/algorithm/2d_convex_hull/04.png)</div>

```cpp
void ConvexHull1(const vector<Point>& points, vector<Point>& hull)
{
	size_t n = points.size();
	if (n < 3)	return;

	size_t leftmost = 0;
	for (size_t i = 1; i < n; ++i)
		if (points[i].x < points[leftmost].x)
			leftmost = i;

	size_t p = leftmost;
	do {
		hull.push_back(points[p]);

		size_t q = (p + 1) % n;
		// 找到q，相对于p是最逆时针的
		for (size_t i = 0; i < n; ++i) {
			// p->i->q方向为逆时针，因此i比q更加逆时针，更新q
			if (Orientation(points[p], points[i], points[q]) < 0)
				q = i;
		}

		p = q;
	} while (p != leftmost);
}
```
&emsp;&emsp;算法的复杂度为 O(m * n)，其中 m 是输出凸包中点的数量，n 是输入点集中点的数量。最坏的情况下，点集中所有点都在输出的凸包上，时间复杂度为 O(n^2)。

### Graham Scan

&emsp;&emsp;算法可以分为两个主要部分：

1. 预处理
  1. 找到最下方的点（y 坐标最小的点），若有 y 坐标相同，则取 x 坐标较小的点。使该点 p0 作为输出凸包的第一个元素 points[0]。
  2. 将剩下 n - 1 个点排序，以 p0 到该点与 x 轴的逆时针夹角从小到大的顺序排序，若有角度相同，则将距离 p0 较近的点放在前面。
  3. 看是否有多个点有相同角度，移除它们，仅保留距离 p0 最远的那个点。此时得到的数组 points 是一条闭合路径。
<div align=center>![](/image/post/algorithm/2d_convex_hull/05.png)</div>

2. 接受或拒绝点
  1. 创建空栈 S，将 points[0]、points[1]、points[2] 入栈。
  2. 处理剩余的每个 points[i]：
    1. 追踪当前的三个点 prev(p)：栈顶的下一个点，curr(c)：位于栈顶的点，next(n)：points[i]，如果它们的方向不是逆时针（向左转），则移除当前栈顶的点 c，否则保留。
    2. 将 points[i] 入栈
<div align=center>![](/image/post/algorithm/2d_convex_hull/06.png)</div>

```cpp
// 交换两个点
void Swap(Point &lhs, Point &rhs)
{
	Point temp = lhs;
	lhs = rhs;
	rhs = temp;
}

// 返回两个点的距离的平方
int DistSq(const Point& lhs, const Point& rhs)
{
	return (lhs.x - rhs.x) * (lhs.x - rhs.x) + (lhs.y - rhs.y) * (lhs.y - rhs.y);
}

// 用于Compare的全局变量
Point p0;

// 排序比较函数，比较与全局变量p0的角度
// p0p1角度 ＜ p0p2角度，返回-1
// p0p1角度 ＞ p0p2角度，返回 1
int Compare(const void* lhs, const void* rhs)
{
	Point* p1 = (Point*)lhs;
	Point* p2 = (Point*)rhs;
	int o = Orientation(p0, *p1, *p2);
	if (o == 0)
		return (DistSq(p0, *p1) <= DistSq(p0, *p2)) ? -1 : 1;
	else
		return (o < 0) ? -1 : 1;
}

// 返回栈顶的下一个Point 
Point NextToTop(stack<Point> &S)
{
	Point p = S.top();
	S.pop();
	Point res = S.top();
	S.push(p);
	return res;
}

void ConvexHull2(vector<Point> points, vector<Point>& hull)
{
	size_t n = points.size();

	// 找到最下方的点，优先左边
	size_t bottommost = 0;
	int ymin = points[0].y;
	for (size_t i = 1; i < n; ++i)
	{
		int y = points[i].y;
		if (y < ymin || (ymin == y && points[i].x < points[bottommost].x))
			ymin = points[i].y, bottommost = i;
	}
	// 将其换到第一个位置
	Swap(points[0], points[bottommost]);

	// 用Compare排序
	p0 = points[0];
	qsort(&points[1], n - 1, sizeof(Point), Compare);

	// 若有多个点与p0角度相同，仅留下距p0最远的那个
	int num = 1;	// 记录删除元素后points的元素数量
	for (size_t i = 1; i < n; ++i) {
		// 当i与i + 1角度相同，则一直移除i
		while (i < n - 1 && Orientation(p0, points[i], points[i + 1]) == 0)
			i++;
		points[num] = points[i];
		num++;
	}

	if (num < 3) return;

	stack<Point> S;
	S.push(points[0]);
	S.push(points[1]);
	S.push(points[2]);

	for (int i = 3; i < num; i++) {
		// 若栈顶第二个点、栈顶点、points[i]的方向不是逆时针
		// 则一直移除栈顶点
		while (Orientation(NextToTop(S), S.top(), points[i]) >= 0)
			S.pop();
		S.push(points[i]);
	}

	// 栈S中元素即为输出
	hull.resize(S.size());
	int i = 0;
	while (!S.empty()) {
		hull[i++] = S.top();
		S.pop();
	}
}
```
&emsp;&emsp;算法的第 1.1 步（找到最下方的点）花 O(n) 时间，第 1.2 步（点的排序）花 O(n * logn) 时间，第 1.3 步花 O(n) 时间。第 2 个步骤中，每个元素入栈和出栈最多一次，假设栈操作 O(1) 时间，则第 2 步总共花 O(n) 时间。因此总体的时间复杂度是 O(n * logn)。

