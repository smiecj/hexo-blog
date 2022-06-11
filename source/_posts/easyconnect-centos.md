---
title: EasyConnect 代理工具容器化运行
description: 网络隔离是更安全的选择
sticky: 1
cover: https://image.winudf.com/v2/image1/Y29tLnNhbmdmb3IudnBuLmNsaWVudC50YWJsZXRfc2NyZWVuXzBfMTU2NzAxNjA3M18wNjE
tags: ['开发工具', '代理', 'docker']
categories: ['开发工具', '代理']
date: 2022-06-10
updated: 2022-06-10
---

[公众号](https://mp.weixin.qq.com/s/r1pOM7CoSMx4-L2GVqNoxg)
[csdn](https://blog.csdn.net/xiaoliizi/article/details/125231965)

## 背景
**EasyConnect** 作为很多国内公司和学校用的代理软件，对上班族和学生党来说还是经常用到的。但是作为一个商用代理软件 ，EasyConnect 并没有开源，而且代理是系统级别的，主机的所有流量都会经过被 EC 进程代理。你也不知道它劫持了流量之后到底做了啥

偶然一天了解到有人已经通过 虚拟机方式 成功启动 easyConnect（git-hagb-docker-easyconnect[1]），相当于把 EasyConnect 运行在一个完全独立的环境，对流量安全来说确实是更好的。只是适配Arm 系统会有一些问题，比如内存占用太高，作者也提供了一些解决思路，不过需要使用者自行尝试

所以一不做二不休，自己动手尝试了使用 centos 系统封装 EasyConnect，并成功测试只让公司流量走 EC 代理。比较不足的点也就是手动配置有一定成本。不过从结果来看还是不错的，至少动手过程中也了解到了一些技术点，最后也写下了这篇博客让大家都可以参考快速配置一下

最后谈一下使用建议：如果你是学生党，那比较推荐通过开源项目 docker-easyconnect 来开启代理，主要是能够少折腾

但如果你是上班族，那就建议自己鼓捣一下。本文提供的思路应该是一个不错的选择，原理和开源项目也差不多

环境说明：
主机: Docker Desktop on Mac
基础镜像: centos 8（platform: amd64）
容器内安装的软件: EasyConnect 麒麟系统版本（兼容 centos）、firefox、clash、xrdp（提供远程桌面，用于打开 EasyConnect 并登录）

## 效果

### 构建镜像

这边把用于代理的镜像构建过程提交到 (git-docker-centos-ec.Dockerfile[2]) 了，拉取代码后即可构建

```shell
## 构建镜像
make build_xrdp

make build_ec

## 运行
make run_ec
```

### 启动容器和服务

![login ec](ec05.png)

![clash](ec06.png)

![内网服务](ec07.png)

下面具体说一下是怎么实现的

## centos 系统初始化

### 安装远程桌面

桌面的主要目的是登录 EC，EC 必须通过界面 输入公司域账号密码登录
Linux 常见的远程桌面软件有 **xrdp** 和 **vnc** ，这边使用 xrdp 进行安装和连接

```shell
# 安装 xrdp
yum -y install xrdp

# 安装 xfce
yum -y groupinstall Xfce

echo "xfce4-session" > ~/.Xclients
chmod +x ~/.Xclients

systemctl enable xrdp
systemctl start xrdp
```

Mac 和 Windows 系统都可以通过 **Microsoft Remote Desktop** 连接
![connect](ec02.png)

![desktop](ec03.png)

windows 系统有一点特殊: 通过 127.0.0.1 连接本地会提示 “原因是你正在运行一个控制台会话” ，需要连接 **127.0.0.2** ，本质上这两个 ip 都是本机地址

### 可选-firefox

这里装浏览器只是用来测试容器内代理是否生效。安装了 clash 之后也可以在主机测试代理，可以不装
chrome([3]) 和 firefox([4]) 这种主流的浏览器都支持在 centos 上安装。我一开始装的 chrome 但是重启过容器之后就发现打不开了。可能是 chrome 太吃内存导致起不来，后面换 firefox 就没遇到这个问题

```shell
# 下载 firefox，解压后直接打开 ./firefox/firefox 即可
wget https://download-installer.cdn.mozilla.net/pub/firefox/releases/101.0/linux-x86_64/en-US/firefox-101.0.tar.bz2
tar -jxvf firefox-101.0.tar.bz2
```

## EasyConnect

在容器内安装 EC 也不是特别复杂，选对和系统匹配的版本就行

### 安装

```shell
# 下载 & 安装
wget http://download.sangfor.com.cn/download/product/sslvpn/pkg/linux_767/EasyConnect_x64_7_6_7_3.rpm
rpm -ivh EasyConnect_x64_7_6_7_3.rpm
```

安装后会自动配置成开机启动，你也能通过 ps 看到 **ECAgent** 和 **EasyMonitor** 进程，分别是流量代理 和 自监控服务

![ec process](ec04.png)

其中 **qemu** 可以理解为虚拟化的实现接口，适配 Mac Arm 系列。还有其他实现方式，对应不同的虚拟机软件，比如 vmware、hyper-v 等

### ECAgent 进程定期强制清理

通过 qemu 启动的 EC 会有内存泄漏的问题：随着运行容器的内存占用越来越大。这个问题可以参考 Hagb 作者对部分 issue 的回复([5])。彻底解决可能需要修改系统调用，简单解决的话，写个 crontab 定期清理 ECAgent 就行，ECMonitor 会自动把它拉起来，这些都是 EasyConnect 自带的进程

```shell
# 每个小时重启一次 ECAgent 进程
RUN echo "0 * * * * nohup ps -ef | grep ECAgent | grep -v grep | awk '{print $2}' | xargs  kill -9" >> /var/spool/cron/root
```

## Clash

把 EC 通过 容器启动起来之后，我们就完成了大头了。接下来的关键就是要分别在容器和主机开启代理，将公司内网的流量指向容器内，非公司内网流量还是正常走。这样才能让主机正常的流量不被 EC 劫持
clash 的完整配置可参考官方wiki([6])

### 容器内部-服务端

安装 linux 版本的 **clash** 并设置 sock5 代理端口作为服务端即可，对应前面 启动容器 开放的 7881 端口

```shell
# 下载 clash linux 版
wget https://github.com/Dreamacro/clash/releases/download/v1.10.6/clash-linux-amd64-v1.10.6.gz
gzip -d clash-linux-amd64-v1.10.6.gz && mv clash-linux-amd64-v1.10.6 clash && chmod +x clash

# 启动方式
## 第一次启动需要下载国家名称和位置信息(https://cdn.jsdelivr.net/gh/Dreamacro/maxmind-geoip@release/Country.mmdb)，启动会比较慢
./clash -d .

# config.yaml, 需要和 clash 可执行文件放到同一个目录
mixed-port: 7890
external-controller: 127.0.0.1:9090

## 这三个配置对应 sock5 代理地址
allow-lan: true
bind-address: 0.0.0.0
socks-port: 7881
```

### 主机-客户端

以域名作为规则，配置转发规则 + 转发目标端口即可

```yaml
proxies:
  - name: socks5_ec
    type: socks5
    server: localhost
    port: 7881

# proxy 分组，只用于展示
proxy-groups:
  ......

# 规则配置，特定域名转发到对应 proxy
rules:
  - DOMAIN-SUFFIX,内网域名,socks5_ec
  ......
```

### 其他配置-容器内部-/etc/hosts
后面调试的时候发现部分内网域名无法正常代理，大概率是 **DNS** 的问题: EC 装在主机的时候，**主机的 DNS 被注入了内网解析的策略**，诸如 gitlab.公司内网域名 这种地址，才能被正常解析。但是通过 主机 -> 容器 -> clash -> EC 的方式，DNS 似乎就没有被注入策略，需要手动配置 /etc/hosts，将域名和 ip 的关系硬写进去才行

```
# /etc/hosts
# git
内网ip gitlab.内网域名.com
......
```

## 主机 EC 卸载

网上有不少人说EC很难卸载干净，实际尝试确实如此，需要好几步，好在已经有人整理了([7])，参考着来做就行

卸载前: 即便主机没有开代理，都有三个进程在后台运行
-- ECAgentProxy 在 Linux 版本的 EC 上没有这个进程，不确定是做啥的

![ec process on mac](ec08.png)

卸载步骤:

- sudo su 进入管理员模式

- 删除 /Library/LaunchDaemons/com.sangfor.EasyMonitor.plist

其中 **plist**([8]) 是 Mac 系统用来设置启动项的工具，相当于 linux 的 systemd
这里相当于删除了 EC 的开机启动项

![ECMonitor](ec09.png)
-- ECMonitor 启动项，声明了启动程序位置

- 删除 /Library/LaunchAgents/com.sangfor.ECAgentProxy.plist

- 打开钥匙串，找到深信服添加的根证书(搜索 sang)，删除

![删除钥匙串](ec10.png)

- 删除应用
直接删除 /Applications/EasyConnect.app 整个目录即可

Windows 系统的卸载方式可以参考 Hagb 作者写的知乎([9])

## 总结
做完了这些东西，还是很有成就感的，有一种看上去非常朴素的乐高，但稍加想象力和努力，就能够拼成各种建筑，而且过程中也能学到很多东西

还要特别感谢一个同事，平时他总能有各种意想不到的点子，经常关注新软件和新技术。这个需求的灵感也是来自于他

总之，对一些软件对系统不合理的侵入，确实应该想办法解决。现在已经不是资源吃紧的时代了，电脑卡往往有一部分原因是使用者没有注意一些细节。从一开始就杜绝软件对系统权限、流量、文件不合理的申请或使用，会比后面回过头再清理方便太多

希望后面还能发现更多软件的问题，多解决多总结~

## 引用

[1] [开源方案](https://github.com/Hagb/docker-easyconnect)

[2] [docker-centos easyconnect.Dockerfile](https://github.com/smiecj/docker-centos/blob/main/Dockerfiles/net/ec/easyconnect.Dockerfile)

[3] [CentOS 7安装谷歌浏览器](https://segmentfault.com/a/1190000022425145)

[4] [How to install latest Firefox browser on RHEL 8 / CentOS 8 Workstation](https://linuxconfig.org/how-to-install-firefox-on-redhat-8)

[5] [issue-MAC M1 pro是否有合适的版本 #120](https://github.com/Hagb/docker-easyconnect/issues/120#issue-1148054348)

[6] [clash官方配置教程](https://github.com/Dreamacro/clash/wiki/configuration)

[7] [Mac 删除深信服 EasyConnect 的 EasyMoniter、ECAgent 的开机启动和根证书的方法](https://www.v2ex.com/t/762221)

[8] [Mac Launchd 介绍和使用](https://www.fythonfang.com/blog/2021/4/19/mac-launchd-daemons-and-agents-tutorial)

[9] [用docker封印EasyConnect并连接远程桌面和数据库](https://zhuanlan.zhihu.com/p/389894063)

[10] [RDP to computer from same computer fails. Why?](https://superuser.com/a/1500416)