---
title: 通过 Ambari 启动 Nebula Gateway 一段时间后会自动退出的问题解决
description: 一个开发过程遇到的小bug的解决
cover: https://upload.wikimedia.org/wikipedia/commons/thumb/0/00/Crab_Nebula.jpg/2048px-Crab_Nebula.jpg
tags: ['nebula', '大数据']
categories: ['大数据', '问题解决']
date: 2021-11-20
updated: 2021-11-20
---

## 参考资料

[网络编程中的 SIGPIPE 信号](http://senlinzhan.github.io/2017/03/02/sigpipe/)

[SIGPIPE 引发的悲剧](https://coderatwork.cn/posts/sigpipe-tragedy/)

[SIGPIPE信号详解](https://www.cnblogs.com/lit10050528/p/5116566.html)

## 问题概述

在 Ambari 中集成了 nebula studio 1.0 版本，启动的组件包括：
- Studio: 通过 node 启动的 前端服务
- Importer: 数据导入工具，可以将本地的CSV 文件导入到 graph
- Gateway: 连接 studio 和 graph 服务的网关服务

然后gateway组件的启动脚本是这样的：
**nohup ./nebula-http-gateway >> /var/log/nebula/gateway.log &**

启动过程集成到了 ambari 中，然后通过界面启动gateway 服务，一开始服务正常启动没问题，但是在 studio 上进行一些图搜索操作之后，就会自动退出，而且服务日志中没有任何报错信息

但是直接在命令行执行的时候，就不会有任何问题，一开始百思不得其解

## 相关基础知识
### 操作系统: stdout、stderr
标准输出和错误输出

在命令行通过 nohup 打印，默认输出位置:
stdout: nohup.out
stderr: 直接忽略

### nebula gateway: 查询图数据逻辑

这里我们看 执行 nebula查询语句的关键方法: Execute
（gateway 版本：1.0）

>service/dao/dao.go

![code](nebula01.png)

![code](nebula02.png)

Request 发给了一个 channel，然后 等待 response channel 接收到回复，最后处理 response ，返回成功 或者是打印 错误信息

### golang 打印日志的目标

#### println: stderr

![code](nebula03.png)

#### fmt.Println: stdout

![code](nebula04.png)

#### log.Printf / log.Println: stderr

![code](nebula05.png)

>func (l *Logger) Output(calldepth int, s string) error {

![code](nebula06.png)

![code](nebula07.png)

### SIGPIPE

[linux-signal](https://man7.org/linux/man-pages/man7/signal.7.html)

SIGPIPE 和 强制终止 kill -9 类似，都是一种发送程序终止的信号。它表示向一个已经终止的socket 通道中写数据

这种情况也是比较常见的，因为可能因为网络的不稳定，服务端向客户端成功发送 FIN 之后，一直没有收到客户端回复的RSP，客户端如果又自行退出，就会导致服务端再次向客户端发送请求时，收到一个 SIGPIPE 信号
对于C 程序，默认情况下是不会忽略这个信号的，收到这个信号就会直接退出。可通过执行 **signal(SIGPIPE, SIG_IGN);** 方法忽略之

## 定位过程
### 打印进程详细日志
strace：可打印进程的内核操作详细信息的工具
strace -p pid: 打印指定进程的详细信息

![strace](nebula08.png)

这里很明显进程退出的原因 就是接收到了 SIGPIPE 信号

### 原因分析
结合前面的基本知识，可大致判断就是 **Ambari 通过一个sub process 执行 gateway 的启动脚本，在执行完成之后，子进程退出了，但是 gateway 依然往子进程的标准输出中打印日志（写日志也是socket操作），就会导致 gateway 接收到 SIGPIPE 信号，并最后退出**

为了最终确定，我们再看一下 ambari 的Execute 方法实现，可看到它会把错误输出定位到标准输出，标准输出默认是和 进程 强绑定的，进程退出了，就无法再打印日志了

>ambari-common/src/main/python/resource_management/core/resources/system.py

class Execute(Resource):

而 gateway 通过 log.Printf 打印 response 的错误信息，会将日志打印到stderr，印证了这个退出的原因

## 问题解决
修改gateway 启动脚本，将 stdout 和 stderr 都重定向到日志文件即可

nohup ./nebula-http-gateway **> /var/log/nebula/gateway.log 2>&1** &

再次操作 nebula studio，看到 gateway 打印的日志能正常在 nohup.out 中打印了

![log](nebula10.png)

## 小总结
虽然最后解决 也就是一行代码的事情，但是发现这个问题根因的过程还是挺有意思的

