---
author: "ysw1912"
date: 2018-08-17T20:10:00+08:00
lastmod: 2018-08-17T21:50:00+08:00
title: "TCP 网络编程三部曲"
tags: [
    "网络编程"
]
categories: [
    "网络编程"
]
---

## SO_REUSEADDR

&emsp;&emsp;允许 TCP server crash/kill 后复用端口，立即重启。

&emsp;&emsp;传统的 fork-per-connection 模型需要使用，fork 出的子进程后，父进程的 listen 退出后，子进程也能立刻侦听该端口。

## SIGPIPE

&emsp;&emsp;向一个已关闭的 socket 或 pipe 写入数据，send() 会返回 -1，errno 为 EPIPE，同时系统会发出一个`SIGPIPE`信号给进程。

&emsp;&emsp;收到 SIGPIPE 的默认行为是终止进程，对于命令行管道效果不错。例如以下命令，用来解压缩一个大的日志文件 “huge.log.gz”：

```
gunzip -c huge.log.gz | grep ERROR | head
```

&emsp;&emsp;找出日志文件中含有 ERROR 的行，head 打印输出的前 10 行，之后就关闭，grep ERROR 则会收到 SIGPIPE 信号，gunzip 也会收到 SIGPIPE，避免将整个大文件解压缩。

&emsp;&emsp;而在网络编程情况下，如果一个 client 关闭 socket，服务器如果不作处理，则会收到 SIGPIPE 而退出，并影响到其他所有 client。因此服务器进程启动时，应<font color=#ff0000>先将 SIGPIPE 信号忽略掉</font>。

## Nagle 算法与 TCP_NODELAY

&emsp;&emsp;TCP socket 默认情况下，发送数据使用`Nagle`算法。能够减少网络中小分组的数目，提高网络吞吐量，但降低了应用程序的实时性。

&emsp;&emsp;如果存在任何一个未被 ACK 的分组，`send()`将不会发送后续数据。因此在 “write - write - read” 情况下，第二个 write 将延迟一个 RTT（往返时间），可以通过一个 buffer，将前两个 write 合并为一个 write 一起 send() 出去来解决。若要在同一个连接上发送并发请求，且这些并发请求可能位于程序的不同部分，无法合并为一个大请求，称为 “request pipelining”，这种情况依然会影响程序的延迟。

&emsp;&emsp;因此建议设置`TCP_NODELAY`禁用 Nagle 算法，如 Go 语言对每个 TCP 连接默认禁用 Nagle 算法。
