---
author: "ysw1912"
date: 2019-09-07T22:00:00+08:00
lastmod: 2019-09-07T22:00:00+08:00
title: "为何删除文件后磁盘空间未释放"
tags: [
    "Linux"
]
categories: [
    "Linux"
]
---

### 问题

&emsp;&emsp;如图，某日志文件 loop.log 正在被进程 log_server 不断写入。
<div align=center>![](/image/post/linux/use_redirect_to_truncate_file/01.png)</div>


其对应代码大致如下：

*log_server.c*
```c
int main() {
  FILE* fp = fopen("loop.log", "a+");
  const char* content = "A test sentence\n";
  for (int i = 1; ; ++i) {
    int n_write = fwrite(content, 1, strlen(content), fp);
    printf("Write %d lines, %d bytes\n", i, n_write);
    sleep(1);
  }
}
```

&emsp;&emsp;当我们用`rm`删除该 23G 的日志文件后，发现当前目录的大小确实由 23G 缩小到 20K，但整个磁盘空间的可用大小依旧没有改变。
<div align=center>![](/image/post/linux/use_redirect_to_truncate_file/02.png)</div>

### 原因

&emsp;&emsp;该文件正在被 server 进程使用，系统不会删除，因此这部分的磁盘空间不会释放，一种方法是中断该进程，但在实际项目中显然不允许我们随意重启服务。

&emsp;&emsp;可以用`lsof`命令列出当前系统打开的文件，或者在`/proc`的对应进程目录下看到该进程占用的文件描述符，其中`fd/3`的硬链接就指向了该日志文件，因此该文件依然存在于文件系统中，`rm`命令并没有起到效果。
<div align=center>![](/image/post/linux/use_redirect_to_truncate_file/03.png)</div>

### 解决

&emsp;&emsp;使用重定向符`>`达到不重启进程也能清空文件的效果。

```bash
find . -type f -name 'loop.log' -exec sh -c '> {}' \;
```

&emsp;&emsp;可以看到，在同样的情况下，不使用`rm`，而是运行上面的命令后，磁盘的可用空间从 146G 增加到 169G。
<div align=center>![](/image/post/linux/use_redirect_to_truncate_file/04.png)</div>
