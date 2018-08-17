---
author: "ysw1912"
date: 2018-08-17T17:35:00+08:00
lastmod: 2018-08-17T20:10:00+08:00
title: "如何正确关闭TCP连接"
tags: [
    "网络编程"
]
categories: [
    "网络编程"
]
---

## 问题

&emsp;&emsp;在使用 TCP 网络编程时，有时发送了一些数据后，要传输的数据的最后几 kb，有时是几 Mb 没有到达。

&emsp;&emsp;具体参见博客：[The ultimate SO_LINGER page, or: why is my tcp not reliable](https://blog.netherlabs.nl/articles/2009/01/18/the-ultimate-so_linger-page-or-why-is-my-tcp-not-reliable)

## 原因

&emsp;&emsp;`send()`成功返回只意味着内核接收了数据，并准备在某些时候发送它们。内核接收数据后，还要把数据包发送到网卡，并在网络中各个网卡遍历，最终到达远程主机。远程主机的内核确认到数据，拥有该 socket 的进程从中读取数据，此时数据才真正到达应用程序，用文件系统的话来说，是 “hit the disk”。

&emsp;&emsp;当调用`close()`关闭 socket fd 时，整个 TCP 连接也关闭了，即使一些数据还在内核的发送缓冲区里，或者已经发送但未被确认。<font color=#ff0000>发送方如果 send() 后立即 close() </font>，就可能出现数据其实还未发送的情况。设置 socket 选项`SO_LINGER`会<font color=#ff0000>尝试将残留在发送缓冲区的数据发送给对方</font>，看似解决了这种问题，但有时依然会出现数据发送不全的问题。

&emsp;&emsp;原因在于，发送方执行 close() 时，如果它的<font color=#ff0000>接收缓冲区中仍有数据没有读取</font>，或者调用 close() 后<font color=#ff0000>有新的数据到达</font>，这时它会发送一个`RST`告知对方数据丢失，没有正常使用`FIN`断开连接，因此设置`SO_LINGER`没有效果。

## 解决

&emsp;&emsp;那么如果发送方先读取了自己接受缓冲区的数据，再 close()，问题会得到解决吗？并不会。这时需要借助`shutdown()`，shutdown() 会确实发送一个`FIN`给对方，说明对方也即将关闭 socket，此时可以<font color=#ff0000>通过 recv() 返回 0 （收到 EOF）检测到接受端的关闭</font>。

&emsp;&emsp;正确的关闭逻辑如下，建议用这种方式代替`SO_LINGER`：

- 发送方：send() → shutdown(WR) → recv() == 0（由接收方 close 导致） → close()
- 接收方：recv() == 0（由发送方 shutdown 导致） → more to send? → close()

&emsp;&emsp;值得注意，如果遇到恶意或错误 client，永远不 close()，则服务器 recv() 不会返回 0（阻塞且 errno == EAGAIN），因此需要加一个超时控制，若 shutdown(WR) 若干秒后 recv() 未返回 0，则直接 close() 强制关闭连接。

&emsp;&emsp;即使如此，<font color=#ff0000>shutdown() 也不能保证接收方接受到所有数据</font>，这只是发送方能做到的最大努力。最好的办法还是像 HTTP 协议那样，附有消息的长度信息，这就需要有能力<font color=#ff0000>自己设计协议</font>。

&emsp;&emsp;还有一种方法，Linux 记录了未确认数据的数量，可以使用`ioctl`的`SIOCOUTQ`选项查询，如果这个数字达到 0，我们<font color=#ff0000>至少可以确认所有的发送数据到达了远程操作系统</font>，只是只能在 Linux 平台下实现。
