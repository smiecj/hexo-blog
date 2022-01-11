---
title: 通过 DockerFile 搭建开发镜像
sticky: 1
description: 一键搭建开发镜像，从此告别繁琐的各种开发环境的安装过程
cover: https://iamondemand.com/wp-content/uploads/2015/04/cool-docker-image.jpg
tags: ['docker', '开发工具']
categories: ['开发工具', 'docker']
date: 2021-12-19
updated: 2021-12-19
---

## 背景  

之前搭建过一个开发镜像，包含了 java、go 语言等基本的开发环境，结合 vscode remote 模式，可在本地直接进行开发，免去了安装各种基础环境和配置环境变量的麻烦
[参考-Docker Desktop 安装方式和开发镜像分享](https://mp.weixin.qq.com/s?__biz=MzU2MDkxMjkwMw==&mid=2247483773&idx=1&sn=a82edd0c3a8063348a7c325fe7f9773d)

但是对于使用者来说，依然有两个并不方便的地方：

- 易用性：对于使用 X86 系统来说，之前的开发镜像确实可以直接用，因为我的镜像就是基于 X86 系统的。但是对于arm 架构系统用户来说，可能就有适配问题了

- 开放性和扩展性：整个镜像的制作过程是封闭的，使用方只能拿到具体的镜像，无法了解到具体的构建过程，也无法对镜像在构建过程进行扩展
-- 比如我还想装其他开发语言，依然只能手动装，而且换台电脑之后可能还得这么来操作一次

综上，为了改进我们的开发镜像的这两点，通过 DockerFile 我们再构建一次之前的开发镜像

## 使用方法

[项目git地址：docker-centos](https://github.com/smiecj/docker-centos)

先直接来看如何用新的开发镜像：直接下载工程 docker-centos，并通过 centos_dev 这个 Dockerfile 构建镜像

构建方法：
```shell
docker build --no-cache -f Dockerfiles/centos_dev -t centos_dev_test .
```

![code](centos-dev_01.png)

等待构建大约10分钟，构建完成后启动容器：
```shell
docker images

docker run -d --hostname code --name centos_dev_test --privileged=true -p 2222:22 centos_dev_test /usr/sbin/init
```

![code](centos-dev_02.png)

容器启动后，通过 Docker Desktop 打开命令行，检查相关依赖是否安装成功：
```shell
source /etc/profile
source ~/.bashrc
java -version
go version
```

![code](centos-dev_03.png)

## 开发过程

### DockerFile

目录：Dockerfiles/centos_dev

这里不需要做太多操作，只需要从 git 下载包含初始化系统脚本的仓库即可

![code](centos-dev_04.png)

### 初始化脚本

目录：scripts/init-dev-system.sh

即初始化整个操作系统的脚本，大概就是下载 + 安装 + 配置环境变量的过程。笔者这里根据自己的开发需要，搭建了 java、go、python 和 nodejs 开发环境，具体版本如下：

- Java: OpenJDK 1.8
- Go: 1.17
- Python: Python3（MiniConda）
- Nodejs: 14.17.0

其他细节说明
- 语言的可执行安装包统一放在 /usr/语言名 目录下，如: /usr/java
- 语言的下载依赖路径统一放在 /home/repo/语言名下，如: /usr/golang
- Java 安装11 和 8 版本：8 用于编译，11 用于 vscode 的 java 插件顺利启动

## 总结
用好工具就是提升开发效率的第一步～