---
title: 树莓派通过 SSD 部署 和 配置内网穿透
description: 基于 树莓派的实践
cover: rasp01.jpeg
tags: ['Linux', '树莓派']
categories: ['生活', '技术实践']
date: 2022-03-12
updated: 2022-03-12
---

## 背景
之前一直有在家部署一个可以长期运行的 Linux 服务器的想法，但首先是自己没有一台 Linux 服务器，不是特别想一直开着台式机主机，其次是就算家里开着台式机，外网也访问不到，只能借助类似向日葵的软件远程操作桌面，所以一直没有实践
但最近把 树莓派 搞好之后发现其实搞起来也不是那么难，再加上有个大佬买了个云服务器，还一下买了几年，于是硬件条件都有满足了。终于找了个时间，先把树莓派通过 SSD 重新安装系统，再结合 内网穿透，后面可以在外网直接操作树莓派，算是有个可以经常跑，也能经常操作和维护的Linux服务器了

## 树莓派和SSD
一开始树莓派是需要通过 SD 卡初始化的，但是 显然 SD卡 无法承担更高的数据读写要求。于是把自己的一张不常用的 SSD 从台式机拿了出来，接到树莓派上并进行了下系统迁移

[How to Boot Raspberry Pi 4 / 400 From a USB SSD or Flash Drive](https://www.tomshardware.com/how-to/boot-raspberry-pi-4-usb)

### 系统写入SSD
这里我们通过 imager 将树莓派系统写入 SSD
[imager官方下载](https://www.raspberrypi.com/software/)

选择一个官方镜像，32位和64位都可以
![jupyter lab](rasp03.png)

等待写入
![jupyter lab](rasp02.png)

### 修改启动选项
登录树莓派（这里还是用 SD卡 启动），安装 bootloader

```sh
sudo apt update
sudo apt full-upgrade
sudo rpi-update

sudo rpi-eeprom-update -d -a
```

将启动选项修改成用 SSD 卡启动

```sh
sudo raspi-config
```

选择 **6 Advanced Options -> A6 Boot Order -> B2 USB Boot**

### 重启树莓派
成功～

![部署效果](rasp04.png)

后面再安装了 docker，把一些后台服务部署到了树莓派上。除了受限于树莓派本身 CPU 和内存（4核4G），只能部署一些简单的服务，不过对自己的个人开发需求来说已经够用了

## 内网穿透

### 原理介绍
本质上就是在保证安全的前提下，建立从公网到内网的连接通道，使得内网机器能够通过一个可靠的公网地址访问
对应现实的例子，类似找香港的代购，代购相当于就是代理，能够按照我们的需求到香港购买一些面免关税的商品（公网发送请求到代理），再帮我们带回来（代理发送请求到内网服务，再将请求结果返回）
因此内网穿透的需求从架构上来看，主要包括三个元素：资源提供商、资源使用者 和 代理服务，如下:

frpc: fast forward proxy client, 内网代理服务
frps: fast forward proxy server, 外网代理服务

![frp架构](rasp05.png)

[git-frp](https://github.com/fatedier/frp)

应用场景：
- ​个人随时操作内网服务器
比如接下来要说的部署 frp 代理服务，就是实现这个需求

- 企业开启远程办公
国内的互联网公司基本都是通过 代理软件（如: easyConnect）+ 专用隧道 实现在外网对内网资源的访问，本质上就是内网穿透

- 将内网其他服务开启到外网（如个人博客站点）
比较大型的个人站点，一般会包含很多数据，需要一定的存储，也需要保证足够的并发访问能力。但是买一个高性能、高存储的云服务器对个人来说肯定成本也不少，这时就可以采用 站点依然部署在内网，只购买一台 主提供流量的 云服务器，通过内网穿透对外开启 HTTP 端口 提供服务的方式。相当于资源提供的压力还是主要在内网机器，外网云服务器只承担流量压力

### 准备
- 内网机器（Linux）
- 一台云服务器（Centos）

### 部署

#### frps（公网）

下载
```sh
wget https://github.com/fatedier/frp/releases/download/v0.40.0/frp_0.40.0_linux_amd64.tar.gz
```

配置
```ini
[common]
# frps 服务提供的端口
bind_port = 7001
# 是否每次网络连接的时候 都进行认证（访问速度 和 安全 方面的选择，并发不大的访问量来说影响不大）
authenticate_new_work_conns = true
# 是否对 frpc 和 frps 之间的心跳检查请求 都进行认证（默认心跳 30s 一次，所以开启认证影响不大）
authenticate_heartbeats = true
# 请求认证方式，可选 token/oidc
authentication_method = token
# 用于请求信息 加密的 key
## 扩展：加密算法 主要用到了 MD5 和 AES，前者用于 Ping 包的校验，后者用于 TCP 请求的校验，具体实现可以参考 frp 作者的 golib 仓库 - git-golib-crypto
token = 123
```

启动
```sh
./frps -c ./frps.ini
```

#### frpc（内网）

下载
```sh
wget https://github.com/fatedier/frp/releases/download/v0.40.0/frp_0.40.0_linux_arm64.tar.gz
```

配置
```ini
[common]
# 公网 ip 地址
server_addr = x.x.x.x
# 公网 frps 服务端口，对应 frps.ini 的 bind_ip
server_port = 7001
# 校验相关的配置 和 frps 保持一致
authenticate_new_work_conns = true
authenticate_heartbeats = true
authentication_method = token
token = 123

# 代理名称（可自行命名）
[ssh]
# 代理协议
type = tcp
# 内网 ssh 端口
local_port = 22
# 在公网开放的端口地址
remote_port = 6001
```

启动
```
./frpc -c ./frpc.ini
```

#### 添加端口访问权限
阿里云：管理控制台 -> 云服务器 -> ECS安全组 -> 手动添加访问规则
分别将 frps 服务的端口 和 内网机器通过 frps 暴露的外网端口 设置访问权限

![阿里云安全策略配置]](rasp06.png)

#### 效果
直接通过ssh云服务器 连接内网服务器:
ssh pi@外网服务器ip -p6001

![ssh](rasp07.png)
