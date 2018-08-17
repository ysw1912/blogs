---
author: "ysw1912"
date: 2018-08-17T20:10:00+08:00
lastmod: 2018-08-17T20:10:00+08:00
title: "网络编程中的一些注意点"
tags: [
    "网络编程"
]
categories: [
    "网络编程"
]
---

## SIGPIPE

&emsp;&emsp;向一个已关闭的 socket 或 pipe 写入数据，send() 会返回 -1，errno 为 EPIPE，同时系统会发出一个`SIGPIPE`信号给进程。

&emsp;&emsp;收到 SIGPIPE 的默认行为是终止进程，对于命令行管道效果不错。例如以下命令，用来解压缩一个大的日志文件 “huge.log.gz”：

```
gunzip -c huge.log.gz | grep ERROR | head
```

&emsp;&emsp;找出日志文件中含有 ERROR 的行，head 打印输出的前 10 行，之后就关闭，grep ERROR 则会收到 SIGPIPE 信号，gunzip 也会收到 SIGPIPE，避免将整个大文件解压缩。

&emsp;&emsp;而在网络编程情况下，如果一个 client 关闭 socket，服务器如果不作处理，则会收到 SIGPIPE 而退出，并影响到其他所有 client。因此服务器进程启动时，应<font color=#ff0000>先将 SIGPIPE 信号忽略掉</font>。
