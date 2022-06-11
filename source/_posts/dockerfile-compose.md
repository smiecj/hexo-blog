---
title: 通过 Docker Compose 本地启动 zk 集群
description: 提升生产效率是使用工具的最终目的
sticky: 1
cover: https://iamondemand.com/wp-content/uploads/2015/04/cool-docker-image.jpg
tags: ['Linux', 'Docker']
categories: ['开发工具', 'Docker']
date: 2022-05-18
updated: 2022-05-18
---

## 项目
如果你想直接看代码，可以直接看我的 [git-docker-centos](https://github.com/smiecj/docker-centos) 项目地址，最近发布了 [v1.2.0](https://github.com/smiecj/docker-centos/releases/tag/v1.2.0) 版本，readme 已经非常详细了，包括项目的使用方式 和 需求规划

本机环境基本只依赖 Docker 的安装，Docker Desktop 的安装教程可参考我之前的[博客-Docker Desktop 安装方式和开发镜像分享](https://mp.weixin.qq.com/s/zmkzhIdL7Da_sfNauhAGRQ)，当然，更详细的教程网上一搜有一堆

[csdn 博客地址](https://blog.csdn.net/xiaoliizi/article/details/124838563)
[公众号博客地址](https://mp.weixin.qq.com/s/4wT_C4Qvywwmh1a9edktxA)

## 背景
之前已经大致将自己平时开发用到的服务和环境，都打包到了 Dockerfile 中，可在本机进行开发环境和基础组件的一键部署。后续自己也进行一些改进，减少了仓库中的shell 脚本文件，整体安装逻辑会更加直观

[关于我为什么要封装自己的 Dockerfile](https://mp.weixin.qq.com/s/BrtGVdtIhv1SoM-KZ1hZCQ)

这个项目当时做到这里就感觉算是完成了一个不小的目标，但随着自己用这个项目的深入，总感觉还差点意思，比如 zk 只能部署一个节点，集群的话需要写三个（对应三个节点）很长的 docker run 指令，加一堆参数（主要是注入 zk 本身的配置），根本没法记，只能放到电脑笔记中，每次拷贝粘贴，非常不方便

给人的感觉，有点像微信的公众号，本来机制是很好的，实时的新闻也有，沉淀下来的技术博客也很多，但是用着用着就感觉没那么好用了，自己不想看的东西越来越多，想要的文章自己又看不到。**好的工具却不能提升学习的效率，类似这种感觉**

另外还有一个小小的痛点: nacos 作为阿里开源的配置管理服务，官方仓库确实已经很完善了，代码在 [nacos 仓库](https://github.com/alibaba/nacos)，容器化部署相关的配置文件放到 [nacos-docker](https://github.com/nacos-group/nacos-docker)，分得很细。但是官方提供的 [standalone-mysql-5.7.yaml](https://github.com/nacos-group/nacos-docker/blob/master/example/standalone-mysql-5.7.yaml) **单机部署配置文件中使用的 nacos 和 mysql 镜像不兼容 Mac M1 系统**。官方也有对应的 issue，但是到发这篇博客的时候，官方还未解决

直到有一天通过 k8s 接触到了 其他管理容器集群的工具，其中 **swarm** 就是通过 compose 管理集群的，突然意识到 **docker-compose** 这个工具应该是比较切合我的需求

主要的原因，就是 对比 **Kubernetes** 来说：k8s 自成一套体系，也牵扯到很多其他技术栈，对初学者来说需要花很多时间去掌握。但是 Compose 其实还是基于 Docker 的基本指令，它对应的配置文件，其实就对应了 Docker 的指令或者参数，对熟悉 Docker 指令的同学来说肯定非常好上手

那还多说什么呢？直接参考官方文档，实践起来

## 最终效果

Compose 这块实现了 zk 集群 和 nacos 服务（依赖 mysql），直接看效果

### 启动 zk 集群
```sh
# 构建操作系统基础镜像
make build_base

# 构建 java 开发镜像
make build_dev_java

# 构建 zookeeper 镜像
make build_zookeeper

# 启动 zk 集群
## 前面构建镜像都是一次性的，后面启动 zk 集群、启动 nacos 都不需要再重复构建
make run_zookeeper_cluster
```

![zk cluster](compose01.png)

### 启动 nacos 服务
```sh
# 构建 mysql 镜像
make build_mysql

# 构建 nacos 镜像
make build_nacos

# 启动 nacos 服务
make run_nacos_mysql
```

![nacos start](compose02.png)

![nacos web](compose03.png)

其中，nacos 服务启动 需要先构建 centos_base、centos_java、centos_nacos 和 centos_mysql 镜像，zk 集群启动需要先构建 centos_java、centos_zookeeper 镜像

第一次构建镜像的话，确实需要总的大概十几分钟的时间，比如 java 的基础镜像，需要先下载几百M 的 JDK，zookeeper 镜像的构建需要编译 zk，但是之后的开发过程就非常顺滑了，**启动服务只需要几秒钟**。这在之前直接使用 Docker 指令启动 zk 集群 还需要粘贴一堆指令，是无法想象的

## 如何实现

### 技术栈

容器技术：**Docker、Docker Compose**
- 熟悉 Docker 指令
- 了解和Docker 相关的术语，比如容器、镜像、Dockerfile 他们的用法
- 了解 Compose 基本用法

后台开发：**Java 语言，Zookeeper、Nacos、MySQL 等中间件**
- OpenJDK 安装
- 中间件安装

脚本
- shell 基本语法

### 构建基础镜像
在通过 Compose 启动服务之前，我们需要把基础镜像先构建好
这里基础镜像可以分为三部分: 

- 操作系统基础镜像（centos_base）
- 开发环境基础镜像（如 Java 开发镜像）
- 组件镜像（centos_zookeeper）

你可以理解为这是一个金字塔三角的结构，就好像你在电脑上安装各种软件，他们是最上层的服务（对应组件），然后软件需要运行在一些系统提供的基础环境中（比如红警在 win10 上跑就需要设置兼容性），最下面一层是操作系统

关于每个镜像里面安装的组件，我在项目的 [Readme](https://github.com/smiecj/docker-centos/blob/main/README_zh.md) 文档中有具体说明

![一部分镜像](compose04.png)

### Compose 配置
这里需要对 Compose 的使用方式有基本了解，对于熟悉 docker 的同学来说不会太难

举个例子：nacos+mysql 的 Compose 配置

```yaml
version: "3.9"
# 定义需要启动的服务，nacos 依赖 mysql, 因此需要定义nacos和mysql 两个服务
services:
  nacos:
    # 镜像名
    image: centos_nacos
    # 启动容器的环境变量，对 nacos 来说，主要需要注入 mysql 的配置
    environment:
      - MYSQL_HOST=mysql
      - MYSQL_PORT=3306
      - MYSQL_DB=d_nacos
      - MYSQL_USER=root
      - MYSQL_PASSWORD=root_NACOS_123
    # 暴露到主机的端口
    ports:
      - "8848:8848"
    # 先启动 mysql 服务，再启动 nacos
    depends_on:
      - mysql
  mysql:
    image: centos_mysql
    # 设置 mysql 登录密码，以及创建一个非默认DB
    environment:
      - ROOT_PASSWORD=root_NACOS_123
      - USER_DB=d_nacos
    # 将当前路径挂载到 mysql 容器里面的特定目录(init_sql)
    # 这里有一个小功能实现: 让 mysql 在初始化的时候查找 init_sql 目录下所有 sql 文件 并 执行，为什么要这么实现在后面实现细节中会讲到
    volumes:
      - "./:/home/modules/mysql/init_sql"
# 创建一个 nacos 和 mysql 服务共用的网络环境
networks:
  my-nacos:
```

## 实现细节
### s6
[s6](https://github.com/just-containers/s6-overlay) 是为了适配容器化场景，针对各个芯片指令集平台都做了适配的 **服务管理器**，类似 systemctl

为什么要引入 s6，主要原因还是 systemctl 在 Mac M1 上不兼容，这个在git 上很多项目都有[讨论](https://github.com/docker/for-mac/issues/6073)，其中使用 s6 就是一种解决方案，只是需要稍微做点适配

比如 mysql，不能使用 service mysql start 指令启动的情况下，就需要把服务启动指令以 s6 支持的方式，写好启动脚本，并在 Dockerfile 中增加注入 启动脚本 的逻辑了

```sh
# centos_base.Dockerfile
## 设置系统启动后执行 /init 以启动 s6 进程
ENTRYPOINT ["/init"]
```

```sh
# mysql.Dockerfile
COPY s6/ /etc/
```

```sh
# s6/services.d/mysql/run
#!/bin/bash
/usr/sbin/mysqld --user=root
```

### mysql 初始化时执行 sql
场景: 一开始我对 mysql Dockerfile 实现的功能只是一键启动，但是后面发现对 nacos 一键部署的场景，还需要支持 初始化时导入 nacos sql ，否则 nacos 无法正常启动

这其实也是 nacos 官方的 compose 配置所使用的 mysql 镜像是 nacos 官方仓库中的镜像的原因。[mysql 官方 Dockerfile](https://hub.docker.com/r/mysql/mysql-server/dockerfile) 并不支持在初始化时执行 sql

所以这里对 mysql Dockerfile 实现了一个 加载并执行 指定目录下的 sql 文件的功能

```sh
# init-mysql.sh
......
## execute init sql
sql_files=`ls -l {mysql_init_sql_home} | grep -E "\.sql$" | sed "s/.* //g" | tr '\n' ' '`
for current_sql_file in ${sql_files[@]}
do
    mysql -uroot -p"${ROOT_PASSWORD}" -f -D${USER_DB} < {mysql_init_sql_home}/${current_sql_file}
done
......
```

### 源替换
在国内网络条件下进行开发你需要解决的一个很基础的问题，就是代理服务器的问题，否则从外网下载开源组件安装包的速度，常常会让你抓狂
这里需要对两种场景分别解决:
对 yum 源、OpenJDK 下载等可以找到国内源 替换 国外地址 的话，直接替换下载地址就可以了

```sh
# env_java.sh
## 使用清华源 mirrors.tuna.tsinghua.edu.cn，还是挺全的
jdk_11_repo="https://mirrors.tuna.tsinghua.edu.cn/AdoptOpenJDK/11/jdk/x64/linux"
......

jdk_8_repo="https://mirrors.tuna.tsinghua.edu.cn/AdoptOpenJDK/8/jdk/x64/linux"
......
```

对不能找到国内源替换的情况，那就只能加快下载速度了，这里我本地有个代理，需要在镜像构建的时候配置到 环境变量 http_proxy 中去
默认 Docker 启动容器的网络模式（driver）下，内部识别到主机的代理地址一般是 host.docker.internal（Mac）或 172.26.16.1（Win10），对应容器内部网络的网关地址
所以做了一个循环逻辑，依次检测指定几个代理端口是否能通，通的话直接配置proxy的逻辑

```sh
# init-system-proxy.sh, 构建 centos_base 镜像时会调用
for proxy_host in ${proxy_host_array[@]}
do
    for proxy_port in ${proxy_port_array[@]}
    do
        ## telnet 一个通的地址很快，这里设置超时 1s
        telnet_output=`timeout 1 telnet $proxy_host $proxy_port 2>&1` || true
        telnet_refused_msg=`echo $telnet_output | grep "Connection refused" || true`
        telnet_host_unknown_msg=`echo $telnet_output | grep "Unknown host" || true`
        if [ -n "$telnet_output" ] && [ -z "$telnet_refused_msg" ] && [ -z "$telnet_host_unknown_msg" ]; then
            echo "export http_proxy=http://$proxy_host:$proxy_port" >> /etc/profile
            echo "export https_proxy=http://$proxy_host:$proxy_port" >> /etc/profile
            break
        fi
    done
    current_proxy=`cat /etc/profile | grep http_proxy || true`
    if [ -n "$current_proxy" ]; then
        break
    fi
done
```

## 扩展: 后面还可以做什么
1、横向扩展
**支持更多服务的本地化集群**

大部分后台中间件，我们在公司里面实践的时候都会遇到部署集群和维护的场景。如果想在自己电脑上研究，当然是能够快速部署集群方便一点。

不过，要能够通过我上面所说的思路去搭集群，并不是容易事，你需要先设想 镜像如何构建，需要把哪些配置作为容器启动参数提供出来，这两步可能会花费大部分时间。不过如果能把这两步搞定，后面 compose 配置的编写就是顺理成章的事了

2、纵向扩展
**学习 K8S**

Compose 毕竟只是通过启动多个容器节点来实现集群 部署的效果，还不涉及到容器编排技术，资源调度这些。想要了解更多技术上的细节，还是最好通过 **swarm、k8s** 这类工具来实践

当然，想精通这两个工具，就没这么简单了，确实需要做好长期啃一门技术，却不一定有很快成效的心理准备

## 资料

[Compose 官方文档](https://docs.docker.com/compose/gettingstarted/)

[国内源替换仓库](https://github.com/eryajf/Thanks-Mirror)

[s6 使用教程（基本是 git 官方 readme 的翻译版，不过作为入门教程还是不错）](https://blog.chobon.top/posts/694278be/)

[nacos issue-Apple Mac M1 docker环境下nacos无法启动](https://github.com/alibaba/nacos/issues/6340)