---
author: "ysw1912"
date: 2018-06-14T18:00:00+08:00
lastmod: 2018-06-14T19:46:00+08:00
title: "链表排序"
tags: [
	"算法",
    "数据结构",
    "C/C++"
]
categories: [
	"算法",
    "数据结构"
]
---

## 链表排序

&emsp;&emsp;在学习`STL`中的双向链表`std::list`时，被它的`sort()`函数惊艳到，发现《STL源码剖析》一书中对该函数草草带过，遂分析一波。

### std::list::sort()

```cpp
void sort()
{
  if (node->next == node || node->next->next == node) return;
  list carry;
  list bucket[64];
  int fill = 0;
  while (!empty()) {
    carry.splice(carry.begin(), *this, begin());
    int i = 0;
    while (i < fill && !bucket[i].empty()) {
      carry.merge(bucket[i]);
      ++i;
    }
    bucket[i].swap(carry);
    if (i == fill)  ++fill;
  }
  for (int i = 1; i < fill; ++i) {
    bucket[i].merge(bucket[i - 1]);
  }
  swap(bucket[fill - 1]);
}
```

&emsp;&emsp;这段代码用到了 3 个`std::list`的成员函数：

- `void splice(const_iterator pos, list& other, const_iterator it);`  
  从`other`转移`it`所指向的元素到`*this`，元素被插入到`pos`所指向的元素之前。  
  时间复杂度`O(1)`。

- `void merge(list& other);`  
  归并两个升序排序链表为一个，不复制元素，操作后链表`other`变为空。  
  若链表`*this`长度为 m，链表`other`长度为 n，则至多进行`m + n - 1`次比较。

- `void swap(list& other);`  
  与链表`other`交换内容。  
  时间复杂度`O(1)`。

### 算法思想

- 首先判断链表是否为空或只有一个元素，若是，直接返回。

- 准备 3 个变量：
  - `list carry`：每次从原链表中搬运一个头节点出来。
  - `list bucket[64]`：64 个桶，桶的容量是`2^桶号`，元素入桶时均有序。
  - `int fill`：当前所用桶的数目。

- while 循环：

  1. 第 8 行：`carry`取数。  
     从原链表取一个元素，若无元素可取，跳转到 for 循环。
  2. 第 9 - 14 行：将所取数入桶`bucket`。  
     `i`从`0`到`fill - 1`循环  
     若`bucket[i]`非空，则将其**<font color=#ff0000>归并</font>**到`carry`；  
     若`bucket[i]`为空，将`carry`中的元素放入`bucket[i]`，并跳出循环。
  3. 第 15 行：维护`fill`。
     若步骤 2 中`i`执行到`i == fill`才跳出循环，即表示`bucket[fill]`有元素（满了），则执行`++fill`，增加一个桶数。

- for 循环：  
  将`bucket[0]`到`bucket[fill - 2]`的每个桶**<font color=#ff0000>归并</font>**到`bucket[fill - 1]`。

### 图解

&emsp;&emsp;例如对链表`3 → 7 → 4 → 1 → 9 → 8 → 5 → 2 → 6`进行排序。
<div align=center>![](/image/post/C&C++/STL02/01.png)</div>

### 总结

&emsp;&emsp;从图中可以形象地看出，这是利用了**<font color=#ff0000>二进制的进位思想</font>**，实现了**<font color=#ff0000>非递归的归并排序</font>**。《STL源码剖析》中并未分析该算法，说它是 quick sort，想必是写错了。

&emsp;&emsp;时间复杂度`O(nlogn)`，空间复杂度`O(1)`（由于是链表，连续存储容器则需要额外空间）。
