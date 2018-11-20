---
author: "ysw1912"
date: 2018-11-20T19:28:00+08:00
lastmod: 2018-11-20T19:28:00+08:00
title: "Win10+VS2017配置OpenGL开发环境（GLFW+GLAD）"
tags: [
    "OpenGL"
]
categories: [
    "OpenGL"
]

---

## GLFW

&emsp;&emsp;GLFW 是一个专门针对 OpenGL 的 C 语言库，它允许用户创建 OpenGL 上下文并显示窗口，它提供了一些渲染物体所需的最低限度的接口。其用来代替之前的 GLUT 库。

### 配置步骤

&emsp;&emsp;访问 [GLFW官网](http://www.glfw.org/download.html/)，下载源码包并解压。也可以直接下载预编译的二进制文件，但必须使用和自己编译环境匹配的版本，为了避免兼容问题，这里我们从源代码开始编译。
<div align=center>![](/image/post/opengl/01/00.png)</div>

&emsp;&emsp;用 [CMake](https://cmake.org/download/) 编译 GLFW 源代码，源代码目录选择 GLFW 源代码的根目录，然后新建一个 build 文件夹作为 build 目录。
<div align=center>![](/image/post/opengl/01/01.png)</div>

点击** Configure **，生成器我这里选择了** Visual Studio 15 2017 Win64 **，这里要根据自己 VS 所使用的编译环境选择，我 VS 常用** x64 **环境因此用 64 位的生成器。若 VS 使用** x86 **环境，这里选择** Visual Studio 15 2017 **，否则之后会出现链接错误！
<div align=center>![](/image/post/opengl/01/02.png)</div>

再次点击** Configure **，最后点击** Generate **，
<div align=center>![](/image/post/opengl/01/03.png)</div>

即可在 build 目录下生成 Visual Studio 的解决方案。
<div align=center>![](/image/post/opengl/01/04.png)</div>

&emsp;&emsp;直接打开解决方案** GLFW.sln **（整个解决方案中有 30 个项目，我们需要的是其中的一个 glfw，其用于生成 glfw3.lib 文件）。在 glfw 项目上右键** 生成 **，编译生成库** glfw3.lib **就会出现在** src/Debug **文件夹内。
<div align=center>![](/image/post/opengl/01/05.png)</div>
<div align=center>![](/image/post/opengl/01/06.png)</div>
<div align=center>![](/image/post/opengl/01/07.png)</div>


## OpenGL 编程测试

```cpp
#include <>

```
