---
title: vscode 使用技巧闲谈
description: 插件化的体验
sticky: 1
cover: https://code.visualstudio.com/assets/docs/languages/javascript/overview.png
tags: ['开发工具', 'vscode']
categories: ['开发工具', 'vscode']
date: 2022-05-31
updated: 2022-05-31
---

## 关于 vscode

如果我们对一个开发者问你平时 **首选 IDE** 是什么，不同语言的开发者估计回答都会不太一样。对于后台来说，近几年比较热门的无疑就是 **Jetbrains** 全家桶系列了，java 用 Idea，go 用 goland，Python 用 PyCharm，体验本身无疑是很棒的。前端开发选择 vscode 就比较多了，主要原因可能是插件支持更完善，而且 vscode 本身就是用 TypeScript 写的。当然还有一些在几年前辉煌过的 Eclipse、Visual Studio Code 等，在一些特定的开发场景还是有一席之地的

那么自己作为后台开发，为什么自己要“反其道而行之” 选择 vscode 呢，主要有两个原因:

- 自己的开发环境并不在本地宿主机，而是在容器内（参考: 仓库 docker-centos），要用容器环境一个最直接的方式就是类似连接远程机器那样，用 ssh remote，而目前来说 vscode 对这种模式支持比较好（也和 vscode 的插件机制相关，插件相当于开发环境，可以安装到远程机器，天生就对这种开发模式适配较好）
- 工作和个人习惯相关，需要经常**在不同的开发环境之间切换**，比如这会需要跑一个 golang 后台服务，过了几分钟突然一个 java 相关的需求来了。如果用 JetBrain 全家桶，就必须在不同软件（虽然操作逻辑类似）之间切换。而用 vscode 就不需要来回切换操作逻辑，很顺手

讲到这里，也要提提 vscode + ssh remote 这种模式的缺点
- 性能不如主机模式
  如果是本机开发，其实直接用 **JetBrains** 就够了， 相当于直接用本地环境，比用容器开发肯定性能会好很多。像我现在开发的时候，电脑主机内存占用60-70算是家常便饭
- 熟练门槛高
  对于我现在的开发模式来说除了本身的开发语言之外，还需要了解一些Docker相关的基本操作，还有 vscode 的快捷键（这个非常重要，说他是 vscode 的灵魂也不为过，快捷键用的少开发效率直接减半）、各个开发语言的插件和配置等
- 特定编程语言下功能不如 Jetbrains 系列
  比如 Idea 可以直接下载和查看源码，vscode 只能查看编译后的 class 文件（虽然也是代码格式，但是少了注释，读开源项目的时候还是比较费劲）

因此这篇文章依然算是**安利**的，比较实用的干货的地方，就是结合自己的经验推荐一下好用的 vscode 插件了。至于其他的技巧，就得看个人的使用习惯，我的方法也不一定适用于其他人

如果你觉得上面使用 vscode 的好处，比较契合自己的习惯，而且不太在乎其带来的影响，那么就可以动手尝试一下了。当然有使用上的感想也欢迎和我私信交流

![show](vscode15.png)

## 常用快捷键

注意: 一些键位我是改过的，因此还是要看个人习惯

快捷键 | 功能 |
-----| ----- |
Command + Control + <- | 跳转到上一个位置
Command + Control + -> | 跳转到上一个位置
Control + ` | 打开终端
Command + Shift + P | 插件功能列表
Command + Shift + F | 全局搜索
Command + Shift + O | 当前文件/类的所有方法
Command + P | 打开当前项目的指定文件
Command + R | 打开最近项目
Control + G | 跳到指定行
F5 | 开始 debug
Shift + F5 | 结束 debug

## ssh remote

### 插件安装
![ssh remote plugin](vscode01.png)

### 开发环境准备
开发环境可以是一个远程宿主机，也可以是你本地的 container 环境
这里还是以 容器环境为例

```
# 启动容器
docker run -d --hostname dev --name dev -p 2000:22 centos_dev_full
```

连接开发机

![ssh remote connect](vscode02.png)

输入账号密码之后，就可以顺利进行 vscode + ssh remote 模式开发了。不过体验上我们还可以继续优化一下

### ssh key
如果不配置免密登录，每次打开一个新项目（新的代码地址），都需要输入一次，下次打开也还要，非常麻烦
所以这里我们把主机的公钥配置到开发机的 ~/.ssh/authorized_keys 中，后续不再输入密码

```
# linux 生成公钥
ssh-keygen

# 查看公钥
cat ~/.ssh/id_rsa.pub

# 将公钥写入服务端受信公钥列表上
echo "公钥" >> ~/.ssh/authorized_keys
```

### git key
还有一个需要频繁输入密码的场景，就是使用git，为了方便我们按照配置ssh 免密类似的方式配一下，把主机生成的 ssh 公钥配置到 git 上

github: **settings -> ssh and GPG keys **

![ssh key github](vscode03.png)

gitee: **设置 -> ssh 公钥**

![ssh key gitee](vscode04.png)

## 各开发环境常用插件

### java

#### Extension Pack for Java

![java extension](vscode16.png)

注意新版本的插件要求运行环境是 JDK11, 所以如果你的主力项目用的是 JDK8 ，还需要给开发机额外装 JDK11，另外环境变量也要配对

```
# /etc/profile
export JAVA_HOME=/usr/java/jdk8路径
export JRE_HOME=$JAVA_HOME/jre
export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar:$JRE_HOME/lib
export JDK_HOME=/usr/java/jdk-11.0.14.1+1
export PATH=$PATH:$JAVA_HOME/bin:$JRE_HOME/bin:$MAVEN_HOME/bin:$GRADLE_HOME/bin
```

这些配置之前还提过 issue 专门问过开发者，最后解决的，亲自试验没问题

另外项目也要显式说明使用的 JDK 版本，maven 和 gradle 配置如下

```
# pom.xml
## 注意: 不同的 module 对应的 pom.xml, 都需要加上这个配置
    <properties>
        <maven.compiler.source>1.8</maven.compiler.source>
        <maven.compiler.target>1.8</maven.compiler.target>
    </properties>
```

```
# build.gradle
  plugins.withType(JavaPlugin) {
    sourceCompatibility = 1.8
    targetCompatibility = 1.8
  }
```

最后打开 **Java: Configure Java Runtime**, 确认项目所使用的 JDK 版本是准确的

![java runtime](vscode17.png)

#### maven
maven 插件在上面装的插件包中自带了，但是有个很奇怪的问题: 插件无法按照 maven 安装路径 /conf/settings.xml 来读取配置，因此诸如本地依赖路径、配置文件路径都会按默认方式从 ~/.m2 路径读取。建议在初始化开发环境的时候配置一个软链指向实际路径，防止通过 maven 下载的依赖包存放在不同路径，造成空间浪费

```
# 创建配置和依赖路径软链
mkdir -p ~/.m2 && ln -s /本地maven 仓库地址 ~/.m2/repository && ln -s /maven安装路径/conf/settings.xml ~/.m2/settings.xml
```

或者手动修改插件 [maven.settingsFile](https://github.com/microsoft/vscode-maven#settings) 配置，不过有点麻烦，不建议这么做

#### gradle
gradle 插件需要另外下载: Gradle Extension Pack

![gradle extension](vscode06.png)

#### formatter
设置 formatter 工具: 打开插件功能列表(command + shift + P), 选择 **Open Java Format Settings With Preview**
第一次会提示还未设置，可以直接用默认的，也可以直接修改 .vscode/settings.json 设置用谷歌的formatter

```
# .vscode/settings.json
"java.format.settings.url": "https://raw.githubusercontent.com/google/styleguide/gh-pages/eclipse-java-google-style.xml",
"java.format.settings.profile": "GoogleStyle"
```

#### lombok
和 Idea 类似，lombok 要想在编写过程中让注解直接生效，也需要额外的机制: 插件: **Lombok Annotations Support for VS Code**

![lombok](vscode07.png)

### golang

#### go
Golang 官方的插件装完之后，在代码编辑这块功能都已经很完备了，装好之后包括测试执行、formatter 等功能都有

![go](vscode08.png)

![安装过程](vscode09.png)

不过关于测试的参数这里，默认的配置往往不符合我们要求。需要额外设置超时时间，打印日志，取消测试缓存等
![vscode-go-setting](vscode10.png)

```
# .vscode/settings.json
"go.testFlags": [
    "-v",
    "-count=1",
    "-timeout=300s"
],
```

### python

#### python

![python](vscode11.png)

如果你的开发机上安装了多套 python，可通过 **Python: Select Interpreter** 进行切换

![python interpreter](vscode13.png)

#### formatter

推荐 flake8，默认的 pylint 要求有点过于严格

打开插件功能列表，搜索 **Python: Select Linter** 并选择 flake8，第一次选择后提示安装即可

自动 format: black

在插件配置中搜索: **python formatting provider**

![black](vscode12.png)

### markdown

插件名: **Markdown All in One**
在写 readme 的时候还是非常好用的，可以直接看到效果: 打开 Markdown: open preview, 并把 preview 并把窗口拖到右边即可

![markdown](vscode05.png)

![markdown preview](vscode14.png)

## 总结

使用 vscode 很长一段时间回头看，插件功能确实很强大，自己现在用到的也只是万众插件中的冰山一角，希望后面有什么新的感受可以再补充一下

最后就希望自己每天都能像今天过节一样吧～

## 引用资料

[如何评价 VS Code Remote Development？](https://www.zhihu.com/question/322952427)

[讨论-买Jetbrains全家桶的都是什么人？](https://www.zhihu.com/question/304808444)

[讨论-IDEA 和 vscode 比较介绍，推荐那个？](https://www.v2ex.com/t/565476)

[vscode官方-Java formatting and linting](https://code.visualstudio.com/docs/java/java-linting)

[v2ex-大家在自己的 Python 项目中倾向使用哪个 Linter？](https://v2ex.com/t/587696)
