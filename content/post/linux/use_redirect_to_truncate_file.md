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

&emsp;&emsp;某日志文件 loop.test 正在被进程 log_server 不断写入

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
<div align=center>![](/image/post/linux/use_redirect_to_truncate_file/01.png)</div>
<div align=center>![](/image/post/linux/use_redirect_to_truncate_file/02.png)</div>

### 原因

&emsp;&emsp;该文件正在被 server 进程使用，系统不会删除，因此这部分的磁盘空间不会释放，一种方法是中断该进程，但在实际项目中显然不允许我们随意重启服务。

<div align=center>![](/image/post/linux/use_redirect_to_truncate_file/03.png)</div>

### 解决

&emsp;&emsp;可以使用重定向符清空文件

```bash
find . -type f -name 'loop.log' -exec sh -c '> {}' \;
```
<div align=center>![](/image/post/linux/use_redirect_to_truncate_file/04.png)</div>
