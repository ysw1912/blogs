---
author: "ysw1912"
date: 2018-08-15T14:30:00+08:00
lastmod: 2018-08-15T21:51:00+08:00
title: "三种I/O多路复用模型"
tags: [
    "网络编程"
]
categories: [
    "网络编程"
]
---

## I/O多路复用

&emsp;&emsp;常见的 I/O 模型有 5 种：

- 阻塞 I/O
- 非阻塞 I/O
- I/O复用
- 信号驱动 I/O
- 异步 I/O

&emsp;&emsp;其中，I/O 复用是通过一种机制，一个进程可以<font color=#ff0000>监听多个</font>文件描述符，一旦某个 fd 就绪（一般是读就绪或写就绪），就<font color=#ff0000>通知</font>程序进行相应的操作。

&emsp;&emsp;目前 Linux 上主要的 I/O 多路复用模型有三种，select、poll、epoll，它们本质上都是同步 I/O，即要求读写事件就绪后自己负责进行读写，这会导致请求进程阻塞，直到 I/O 操作完成。

## select

```c
#include <sys/select.h>
int select(int maxfdp1, fd_set* readset, fd_set* writeset, fd_set* exceptset, 
           const struct timeval* timeout);
```

- `maxfdp1`参数指定内核监控的文件描述符个数，描述符 0, 1, 2, ..., maxfdp1 - 1 将被测试。该值受限于`<sys/select.h>`中定义的`FD_SETSIZE`常值，x86 系统下一般为 1024。
- 中间三个相同类型的参数指向`fd_set`（描述符集）的数据类型，分别表示监控的文件描述符集的<font color=#ff0000>读、写、异常</font>三种属性。fd_set 类型变量每一位代表了一个描述符，是一个由 1024 个二进制位构成的`bitmap`。select 返回时，它们作为传出参数，表示相应事件就绪的文件描述符集。
- `timeout` 设置 select 的超时时间。
  - 若设为 NULL，则将 select 置于阻塞状态，直到有 fds 准备好 I/O 时才返回；
  - 若设为 “0 秒 0 毫秒”，则将 select 设为非阻塞，检查 fds 后立即返回，成为轮询（polling）；
  - 若设置 timeout 值大于 0，则在超时时间内有事件到来才返回，超时后不管怎样一定返回。

#### 原理

&emsp;&emsp;具体的源码分析参见该博客：[select(poll)系统调用实现解析](https://blog.csdn.net/lizhiguo0532/article/details/6568964)。这里仅做大致梳理。

**`select()`系统调用**

1. 调用 copy_from_user() 从用户空间取 timeout 数据到内核空间。
2. 调用`core_sys_select()`实现 select 核心工作。
3. 若有设置超时值，则拷贝离超时时刻的剩余时间到用户空间。

**`core_sys_select()`主要工作**

1. 创建一个 fd_set_bits 类型变量，包装 6 个 unsigned long*，用于存储三个描述符集 readset、writeset、exceptset 的入值和返回结果。
2. 从用户空间取得三个 fd_set，且先将返回结果初始化为 0，准备工作完毕。
3. 调用`do_select()`实现核心的轮询工作。
4. 将结果拷贝回用户空间。

**`do_select()`主要工作**

1. 取出 32 个文件描述符对应的 bitmap，若其中没有待监听的描述符，则跳入下一轮 32 个描述符的循环。这里每次循环检测 32 个描述符，刚好一个 unsigned long 型数（x86）。
2. 如果本次 32 个描述符中有待监听的描述符存在，首先找到那一位的 fd。调用驱动程序中的`poll`函数，其中`__pollwait()`函数将当前进程添加到对应 fd 的等待队列中。当该 fd 有事件到来时，就会唤醒这个进程。`poll`函数返回时返回一个表示事件是否就绪的掩码。
3. 根据`poll`返回的 mask 给结果 bitmap 赋值，返回给上级函数 core_sys_select()。
4. 若轮询一遍未发现就绪事件，则根据所设超时时间进入休眠。

#### 使用场景

&emsp;&emsp;从 select 的实现来看，它有如下缺点：

1. 监听的文件描述符数量有 FD_SETSIZE 的限制。
2. 需要将整个描述符集的 bitmap 在用户空间与内核空间来回拷贝，这在 fd 很多时开销巨大。
3. 内核需要轮询整个监听 fd 集，以测试其中是否有就绪者。
4. select 返回时，该进程从所有监听的 fd 的等待队列中移除。而下次 select 再次重新传入所有监听的 fd，再重新将进程挂在到监听的 fd 的等待队列中。重复的开销太大。
5. 用户获取事件时，需要遍历整个监听 fd 集。

&emsp;&emsp;因此，解决 1024 以下客户端时的小型并发时使用 select 比较合适，但如果客户连接过多，由于 select 采用轮询，会大大降低服务器效率。

## poll

```c
#include <poll.h>
int poll(struct pollfd* fdarray, unsigned long nfds, int timeout);

struct pollfd
{
    int    fd;		// 需要检测的 fd
    short  events;	// fd 上关心的事件，传入参数
    short  revents;	// fd 上发生的事件，作为 poll 返回时的传出参数
};
```

&emsp;&emsp;select 使用三个 bitmap 表示的三个 fd_set，它们既作为传入参数，又作为传出参数。

&emsp;&emsp;poll 不同于 select：

1. 使用指向 pollfd 结构的指针实现，分离了监视事件和发生事件，调用前后不需要重置。若不再监控某 fd，可把 pollfd 中的 fd 设置为 -1。
2. 不再把事件分为三组（读/写/异常），而由调用者自己设置，其值为 “POLLIN” 等常值的按位或。
3. 内核中不使用 bitmap 组织描述符，使用链表，因此没有最大数量的限制。
4. int 型的 timeout 是毫秒级时间。

#### 原理

&emsp;&emsp;除了对于描述符集合的存储方式不同外，poll 与 select 本质上没有区别，poll 只解决了 select 最大描述符数量的限制，但依然在内核中采用轮询遍历 fd，并且需要在用户空间与内核空间来回拷贝数据，随着 fd 的增加会造成服务器性能显著下降。

## epoll

&emsp;&emsp;epoll 是 <font color=#ff0000>Linux 特有</font>的 I/O 复用函数，避免了 select 和 poll 的缺点，实现上 epoll 使用<font color=#ff0000>一组函数</font>来完成任务。

&emsp;&emsp;对于长期监听的 fd，以及对这些 fd 期待的事件也不会改变时，每次调用 select 或 poll 仍然需要一次从用户空间到内核空间的拷贝。因此我们希望<font color=#ff0000>让内核长期保存所有需要监听的 fd 以及对应事件，并在需要时对部分 fd 以及期待事件进行修改</font>。

&emsp;&emsp;因此 epoll 把用户关心的 fd 上的事件放在内核里的一个事件表里，并用一个额外的 fd 来唯一标识内核中的这个事件表，该 fd 的创建如下：

```c
#include <sys/epoll.h>
int epoll_create(int size);	// size提示事件表的大小，建议内核监听的fd个数
```

&emsp;&emsp;并用如下函数操作 epoll 的内核事件表：
```c
int epoll_ctl(int epfd, int op, int fd, struct epoll_event* event);

struct epoll_event
{
    __uint32_t    events;	// epoll事件
    epoll_data_t  data;		// 一般使用data.fd，指定事件从属的目标fd
};
```

&emsp;&emsp;其中 op 参数指定操作类型，有如下 3 种：

- EPOLL_CTL_ADD 往事件表中注册 fd 上的事件
- EPOLL_CTL_MOD 修改事件表中 fd 上的事件
- EPOLL_CTL_DEL 删除事件表中 fd 上的事件

&emsp;&emsp;epoll 系列系统调用的<font color=#ff0000>主要接口</font>是 epoll_wait() 函数，它在一段超时时间内等待一组 fd 上的事件：
```c
int epoll_wait(int epfd, struct epoll_event* events, int maxevents, 
               int timeout);
```

&emsp;&emsp;epoll_wait 函数如果检测到事件，就将所有就绪的事件从内核事件表中拷贝到它的第二个参数 events 指向的数组中，这个数组<font color=#ff0000>只用于传出就绪事件</font>。

&emsp;&emsp;对于一个 fd，epoll 除了提供 select/poll 那种 I/O 事件的 LT（Level Trigger，电平触发）模式，还提供 ET（Edge Trigger，边沿触发）模式， ET 模式是 epoll 的<font color=#ff0000>高效</font>工作模式。

- fd 采用 LT 模式：epoll_wait() 检测到该 fd 上有事件发生并通知应用程序后，若应用程序未立即处理该事件，或没有 read/write 完该 fd 上的所有数据，当下次调用 epoll_wait() 时，epoll_wait() 还会再次向应用程序通告此事件，直到该事件被处理。

- fd 采用 ET 模式：epoll_wait() 检测到该 fd 上有事件发生并通知应用程序后，<font color=#ff0000>后续的 epoll_wait() 不再向应用程序通知这一事件</font>，降低了同一 epoll 事件被重复触发的次数。

#### 原理

&emsp;&emsp;详细地源码分析可参见[The Implementation of epoll](https://idndx.com/2014/09/01/the-implementation-of-epoll-1/)。这里仅做大致梳理。

&emsp;&emsp;调用 epoll_create() 时，内核会通过 slab 分配器开辟一块高速 cache，并在其中创建一个事件表，用来存储所要监听的所有 fd 上的事件。存储所用的数据结构就是[红黑树](https://ysw1912.github.io/post/cc++/rbtree_delete/)，红黑树的插入、删除、查找的复杂度都是`O(nlogn)`，效率很高。

&emsp;&emsp;内核创建红黑树后，同时会建立一个双向链表 readylist，该`就绪链表`用于存储所有就绪事件。

- 当执行 epoll_ctl() 时，除了操作事件表（红黑树）外，还会<font color=#ff0000>为该事件在 fd 相应的设备驱动程序上注册一个回调函数`ep_poll_callback`，当该 fd 上有事件到达时就调用这个回调函数，回调函数会将该 fd 上发生的事件放入到 readylist 中</font>。
- 当 epoll_wait() 返回时，通过 readylist 中的每项 fd 对应的设备驱动的`poll`方法，获取 events 数组并拷贝到用户空间中，并清空 readylist。如果该 fd 处于 LT 模式，且该 fd 上有未处理事件时，会将该事件放回至 readylist。

#### 使用场景

&emsp;&emsp;epoll 作为 Linux 下 select/poll 的增强版本，有如下优势：

1. 不必每次等待事件前都要重新准备要监听的 fd 集合，通过创建一个事件表复用了这些集合。
2. 采用<font color=#ff0000>回调</font>的机制检测就绪事件，只有活跃可用的 fd 才会调用回调函数，效率与连接的总数无关。比起轮询，时间复杂度从`O(n)`降低到`O(1)`。
3. 即使在使用 epoll_ctl() 往事件表上注册 fd 事件时，也不会影响 epoll_wait() 的返回 readylist 的数据。
4. 用户获取事件时，无须遍历整个监听的 fd 集，只要遍历那些被内核 I/O 事件异步唤醒而加入 readylist 的 fd 集合即可，极大地提高了应用程序索引就绪 fd 的效率。

&emsp;&emsp;因此，epoll 是目前 linux 大规模并发网络程序中的首选模型，适合连接数量巨大，但同一时刻活跃连接数量较少的场景。如果同一时刻活跃读较高，回调函数被触发得过于频繁时，epoll 对于 select/poll 的提升并不明显。
