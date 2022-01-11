---
title: Mac 预装软件整理
description: 介绍 mac 的一些预装软件，包括开发工具
sticky: 1
cover: http://up.iosdesk.com/pic/80/c4/80/80c48029bdf373fa0d75dd00b5afe76e.jpg
tags: ['mac', '开发工具']
categories: ['开发工具', 'mac']
date: 2022-1-10
updated: 2022-1-10
---

## 前言
最近发现在 mac 上装的软件是越来越多了，索性就整理一下自己装过的 mac 必备软件，方便后面用新机的时候直接参考教程无缝切换

## 参考网站
[博客-15款好用的Mac软件推荐](https://www.v1tx.com/post/best-mac-apps/)

## 效率工具

### brew
功能: 软件安装工具，一键安装指定软件，无需关注繁琐的安装配置，对于一些工具类软件，比如下面提到的性能测试软件，还是比较实用的
[官方文档](https://docs.brew.sh/)

[git-Homebrew/brew](https://github.com/Homebrew/brew)

安装方式
```
/bin/bash -c "$(curl -fsSL https://cdn.jsdelivr.net/gh/ineo6/homebrew-install/install.sh)"
```

替换国内源
```
# 替换 brew.git
cd "$(brew --repo)"
git remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git

# 替换 homebrew-core.git
cd "$(brew --repo)/Library/Taps/homebrew/homebrew-core"
git remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git

# 更新配置
brew update
```

扩展: 给其他软件自定义安装脚本
[博客-将软件发布到 Homebrew](https://www.jianshu.com/p/df351f34c160)
[博客-Formula Cookbook](https://docs.brew.sh/Formula-Cookbook)

### alfred

自带非常多快捷键工具，我用得比较多的就是粘贴板，可以帮我记住最近一段时间复制过的内容。主要功能有：
- Web Search 文件搜索
- Clipboard History 剪贴板历史
- Snippets 文本片段
- System 系统（系统操作快捷键，如清空回收站）

alfred 本身的快捷键配置
![shortcut](alfred01.png)

剪贴板历史配置
![clipboard history](alfred02.png)
（截图只是表示个人使用习惯）

[下载地址](https://macwk.com/soft/alfred-4)

[参考-Mac 效率工具必备神器 —— Alfred](https://michael728.github.io/2020/09/23/tools-dev-mac-alfred/)

### bartender
mac 的状态栏在右上角，但是不像 windows 那样有默认的隐藏功能，不方便管理
bartender 就是不错的状态栏管理工具

[下载地址](https://macwk.com/soft/bartender-4)

![bartender](bartender.png)

## 开发常用

### zsh
zsh 本身不是 shell，它只是在终端基础上套了个壳，相当于穿了件外套，你可以换不同样式的外套，也可以给衣服加口袋

虽然 mac 本身使用的是 zsh，但是版本可能比较旧，建议更新到最新版

配置插件
```
# vim ~/.zshrc
plugins=(git osx autojump zsh-autosuggestions zsh-syntax-highlighting)

# 自动提示插件
git clone git://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions
# 语法高亮插件
git clone git://github.com/zsh-users/zsh-syntax-highlighting $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
```

[参考-Mac 环境安装并配置终端神器 oh-my-zsh](https://a1049145827.github.io/2019/05/15/Mac-%E7%8E%AF%E5%A2%83%E5%AE%89%E8%A3%85%E5%B9%B6%E9%85%8D%E7%BD%AE%E7%BB%88%E7%AB%AF%E7%A5%9E%E5%99%A8-oh-my-zsh/)

### iterm
一款比较好用的终端工具，支持多窗口
[下载地址](https://iterm2.com/downloads.html)

#### 使用技巧 - 快速登录指定节点
iterm 本身没有记录节点列表的功能，如果需要随时连接指定节点（在公司一般都会用到），我们可以通过shell 脚本 + host 配置文件的方式，来实现快速登录指定节点

```
# vim /etc/my_hosts
## 我的配置方式是 节点名 + 环境名 + 实际 ssh 连接的地址 + 端口
docker local root@localhost 22
docker db root@localhost 23
cloud dev root@云主机ip 22
compile dev root@内网编译专用机ip 22

# vim /usr/local/bin/goto
#!/bin/sh
set -euxo pipefail

echo "hello go!"

if [ $# -lt 2 ]; then
        echo "Invalid input!"
        exit
fi

node_name=$1
env_name=$2

login_node_full_info=`cat /etc/my_hosts | grep "$node_name $env_name"`
if [ -z "$login_node_full_info" ]; then
        echo "Node not found!"
        exit
fi

IFS=' ' read -r -a node_split_arr <<< "$login_node_full_info"
#ssh -p${node_split_arr[3]} ${node_split_arr[2]}
ssh -o "IdentitiesOnly=yes" -i ~/.ssh/自己生成的免密密钥，可将公钥加到想登录的节点上，不需要每次都输密码  -p${node_split_arr[3]} ${node_split_arr[2]}
```

这样直接输入 goto 节点名 环境名 即可登录指定节点

#### 扩展: 支持 lrzsz（文件上传和下载工具）

默认iterm 是不支持rz、sz 的，执行后会卡住，需要设置适配的脚本，比如执行 rz 的时候，打开文件列表

下载适配脚本
```
cd /usr/local/bin
sudo wget https://raw.githubusercontent.com/RobberPhex/iterm2-zmodem/master/iterm2-recv-zmodem.sh
sudo wget https://raw.githubusercontent.com/RobberPhex/iterm2-zmodem/master/iterm2-send-zmodem.sh

sudo chmod 777 /usr/local/bin/iterm2-*
```

修改配置
![iterm config](iterm01.png)

![iterm config](iterm02.png)


### lrzsz

文件上传、下载工具
当然多文件上传/下载 不支持确实比较麻烦，单文件的操作还是比较方便的

```
brew install lrzsz
```

### Docker

Docker 对于开发者的重要性我在前面[公众号文章](https://mp.weixin.qq.com/s/zmkzhIdL7Da_sfNauhAGRQ)有提过，主要就是开发环境的模拟和隔离，比如现在需要在 Arm 版本的 Mac 上开发 X86 的程序，就需要模拟一个 X86 的环境，直接通过 Docker 启动一个 X86 的镜像是比较方便的

建议在官网下载最新版，使用 brew 安装的版本可能会稍微旧一点

[官网下载](https://www.docker.com/products/docker-desktop)

mac 电脑建议根据，比如如果在 M1 版本上运行 X86 的镜像，可能会有一些软件不兼容的情况
这边我还整理了开发镜像的制作方式，[参考博客](https://smiecj.github.io/2021/12/18/dockerfile-centos-dev/)，可一键搭建包含 java、go 等语言的开发镜像

### Conda
安装 Python 的最佳工具，对不同环境之间可进行较好的隔离

[下载地址](https://docs.conda.io/en/latest/miniconda.html)

建议下载脚本，下载完成后通过 sh 执行即可，然后会有一些设置安装路径的操作，建议放在 **/Users/用户名/miniconda** 目录下

```
sh /Users/username/Downloads/Miniconda3-latest-MacOSX-arm64.sh
```

## 性能测试

### glances

支持各操作系统的性能指标查看工具，使用 python 编写

[官网](https://nicolargo.github.io/glances/)
[git-nicolargo/glances](https://github.com/nicolargo/glances)

```
brew install glances
```

![glances](glances.png)

### Speed Test

磁盘速度测试，在 app store 上直接搜索: blackmagic-disk-speed-test

![speed test](speedtest.png)