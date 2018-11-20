---
author: "ysw1912"
date: 2018-11-20T19:28:00+08:00
lastmod: 2018-11-20T20:24:00+08:00
title: "Win10+VS2017配置OpenGL开发环境（GLFW+GLAD）"
tags: [
    "OpenGL"
]
categories: [
    "OpenGL"
]

---

## GLFW

&emsp;&emsp;**GLFW **是一个专门针对 OpenGL 的 C 语言库，它允许用户创建 OpenGL 上下文并显示窗口，它提供了一些渲染物体所需的最低限度的接口。其用来代替之前的 GLUT 库。

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

&emsp;&emsp;直接打开解决方案** GLFW.sln **文件（整个解决方案中有 30 个项目，我们需要的是其中的一个 glfw，其用于生成 glfw3.lib 文件）。在 glfw 项目上右键** 生成 **，编译生成库** glfw3.lib **就会出现在** src/Debug **文件夹内。
<div align=center>![](/image/post/opengl/01/05.png)</div>
&nbsp;
<div align=center>![](/image/post/opengl/01/06.png)</div>
&nbsp;
<div align=center>![](/image/post/opengl/01/07.png)</div>

## GLAD

&emsp;&emsp;由于 OpenGL 只是一个标准/规范，具体的实现是由驱动开发商针对特定显卡实现的。而 OpenGL 驱动版本众多，它大多数函数的位置都无法在编译时确定下来，需要在运行时查询。所以任务就落在了开发者身上，开发者需要在运行时获取函数地址并将其保存在一个函数指针中供以后使用。但这样写出的代码复杂繁琐，因此我们需要 GLAD。

&emsp;&emsp;**GLAD **是目前最流行的开源库，能帮我们简化这个流程。在此之前，我们首先用** OpenGL Extension Viewer **（[softonic下载页](https://opengl-extensions-viewer.en.softonic.com/)）查看自己的 OpenGL 版本，我这里是** 4.0 **。
<div align=center>![](/image/post/opengl/01/08.png)</div>

&emsp;&emsp;打开 [GLAD在线服务页面](http://glad.dav1d.de/) ，默认语言为** C/C++ **，选择** OpenGL **，API 选择使用的对应的版本，Profile 选择** Core **，默认勾上了** Generate a loader **，点击** GENERATE **。
<div align=center>![](/image/post/opengl/01/09.png)</div>

新窗口中右键下载压缩包** glad.zip**并解压。


## 配置 Visual Studio 工程

&emsp;&emsp;该有的库都有了之后，我们需要让 VS 知道库和头文件的位置。推荐的方式是建立一个新的目录，里面包含** include **和** lib **文件夹，在这里存放 OpenGL 工程用到的所有第三方库和头文件，方便库的管理。上面获得的库的文件组织结构如下：
<div align=center>![](/image/post/opengl/01/10.png)</div>
&nbsp;
<div align=center>![](/image/post/opengl/01/11.png)</div>

&emsp;&emsp;新建 Visual C++ 空项目，在项目** 属性 **的** VC\+\+ **选项卡中包含目录以及库目录中添加之前建立的** include **和** lib **文件夹，这样就可以使用``<GLFW/..>``和`<glad/glad.h>`来引用头文件。
<div align=center>![](/image/post/opengl/01/12.png)</div>

要链接一个库我们必须告诉链接器它的文件名，在** 链接器 **选项卡里的** 输入 **选项卡里添加** glfw3.lib **文件。由于这里使用 Windows 平台（Linux 下需要链接** libGL.so **库文件），** opengl32.lib **已经包含在 Microsoft SDK 里，它在 VS2017 安装时就默认安装了，这里只需将** opengl32.lib **添加进链接器里即可。
<div align=center>![](/image/post/opengl/01/13.png)</div>

&emsp;&emsp;最后将** glad.zip**提供的** glad.c **文件添加到工程中，所有工作就完成了。

## OpenGL 编程测试

```cpp
#include <glad/glad.h>
#include <GLFW/glfw3.h>

int main()
{
    return 0;
}

```
