---
author: "ysw1912"
date: 2019-07-11T10:00:00+08:00
lastmod: 2019-07-11T12:50:00+08:00
title: "GFlags使用"
tags: [
    "C/C++"
]
categories: [
    "C/C++"
]
---

## GFlags使用

GFlags 是 Google 开源的一个命令行 flag 库。与 getopt 之类不同，flag 的定义可以散布在各个源码中，而不用放在一起。一个源码文件可以定义一些它自己的flag，链接了该文件的应用都能使用这些flag，这样就能方便地复用代码。但要注意，如果不同的文件定义了相同的 flag，链接时会报错。

-----

### DEFINE: 在程序中定义 flag

定义一个