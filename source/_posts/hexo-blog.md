---
title: Hexo 博客搭建教程
cover: /img/blog_img/hexo.png
tags: ['个人博客', 'hexo']
categories: ['个人博客', '工具使用']
---

## 效果
[博客首页](https://smiecj.github.io/)
![blog front page](hexo_blog_01.png)

![blog front page](hexo_blog_12.png)

## 背景
之前自己的博客都是放在csdn上，分类管理起来不是很方便，而且分类在左下角，不是特别显眼的地方
![csdn page](hexo_blog_03.png)

公众号的标签功能还可以，不过自己还是希望有个个人站点能专门管理写过的博客，主题最好是能一目了然，不仅仅是别人看着方便，以后自己整理资料的时候找得也方便

既然有这个需求，那就试试呗，看看个人站点怎么搭建，据说不难的

## 踩坑记 - hugo工具短暂的体验
hugo 是一个用golang 写的博客搭建工具，主要功能是可一键生成博客，我们自己只需要写markdown 格式的文章就行了，前端静态文件都是通过hugo 进行渲染生成的。方便是方便，但是一直没有找到特别满意的主题。
其实自己对主题的要求也没有说特别高，主要是要简洁、重点明了就好了，那种特别花哨、或者是基本功能欠缺的主题都是不考虑的
所以最后放弃了hugo。一次偶然的机会，和一个前端同学聊，知道了有hexo 这样一个工具，同样是生成博客的，那就试试呗

[参考-hugo搭建教程](https://jeshs.github.io/2019/01/hugo%E6%90%AD%E5%BB%BA%E5%8D%9A%E5%AE%A2%E4%B8%80%E6%90%AD%E5%BB%BAhugo%E5%8D%9A%E5%AE%A2/)

>hugo基本指令:
```
创建一篇博客:
hugo new site myblog
启动服务:
hugo server -D --bind="0.0.0.0"
```

## hexo 主题介绍
hexo 和 hugo 最大的优势我觉得就是主题库了，这里介绍几个个人感觉还不错的：

主题 | 风格 | demo
-----| ----- | -----
[Indigo](https://github.com/yscoder/hexo-theme-indigo) | 蓝色主题、简洁 | [wuyang的个人博客](https://wuyang910217.github.io/)
[butterfly](https://github.com/jerryc127/hexo-theme-butterfly) | 首页展示大幅背景图，表现力强 | [云玩家](https://yunist.cn/)
[melody](https://github.com/Molunerfinn/hexo-theme-melody) | 白色主题、简洁 | [MARKSZのBlog](https://molunerfinn.com/)

其实自己也是后面看了这些主题的样式，才发现原来好多大神的个人站点都是通过 hexo 搭建的，有些前端技术比较厉害的，还会尝试自己去魔改，希望自己也有一天可以尝试一下

## 本地搭建方式
### 环境准备
[hexo](https://github.com/hexojs/hexo) 是 node 开发的框架，所以需要通过 npm 来安装

>安装hexo 框架
```
npm install -g hexo-cli
```

>创建博客工程
```
hexo init myblog
```

>工程结构简述

![hexo structure](hexo_blog_04.png)

```
_config.yml: 主配置文件，后续修改主题之类的就是改这里
themes: 主题目录
scaffolds: 博客模板，通过 hexo new page 生成的页面都以这里的md 文件为模板
source: 存放用户资源
package.json: 本质上 hexo 博客还是一个前端项目，所以在这里管理依赖
```

### 设置主题
这一步主要是在 **themes** 目录下，存放主题代码目录，这样 hexo 启动博客主页的时候，就是以你放的主题来生成了
有两种下载主题的方式：你可以直接将主题git 代码下载下来，放到themes 目录，或者是fork 一份主题仓库，通过 git submodule clone 一份代码。如果有兴趣自己做主题魔改，更建议后者

通过 git submodule 下载：
```
git submodule add git@github.com:主题仓库.git themes/主题名称
```

下载完成之后，将_config.yml 中的主题名称修改一下
![hexo structure](hexo_blog_05.png)

安装渲染工具
```
npm install hexo-renderer-pug hexo-renderer-stylus --save
npm install --save hexo-renderer-pug hexo-renderer-jade hexo-generator-feed hexo-generator-sitemap hexo-browsersync hexo-generator-archive hexo-renderer-stylus
```

### 启动博客

>清理静态文件

```
hexo clean
```

>生成静态文件

```
hexo g
```

>启动服务

```
hexo server -w -p 3000

# 启动服务
# -w: watch，监听文件变化
# -p: port，启动端口
```

到这一步完成，博客基本框架就算搭建成功了~

## 基本配置的介绍
这里我们对一些博客配置做简单的了解，方便后续进行主题设置。当然博客部署完成之后，也可以直接部署到github 上，先不管这些配置。你也可以直接跳到下一节内容进行参考。
如果想了解大部分的配置，建议参考下面的官方教程
[参考-官方教程](https://butterfly.js.org/posts/4aa8abbe)

### 网站信息
站点基本配置

![blog config](hexo_blog_06.png)

头像和首页背景图

![head config](hexo_blog_07.png)

### 文章
文章封面: 设置cover属性
![blog top img config](hexo_blog_08.png)

效果:
![blog top img show](hexo_blog_09.png)


### 顶部栏
![blog top config](hexo_blog_10.png)

其中，标签、分类页面可通过下面的指令新建:
```
hexo new page tags
hexo new page categories
```

## 部署到github站点

### github 创建仓库
github 能够识别 用户名.github.io 的仓库名，并部署这个仓库的静态文件生成站点，站点地址就是 用户名.github.io
![blog deploy config](hexo_blog_11.png)

### 配置准备
修改博客根目录的 config.yml 文件:
```
deploy:
  type: git
  repo: <repository url> #https://bitbucket.org/JohnSmith/johnsmith.bitbucket.io
  branch: master
```

这样先执行 **hexo g** 生成静态文件之后，再执行 **hexo d** 就可以将静态文件 提交到站点仓库上了
如果是在本地开发，建议 repo 配置成 ssh 的地址，部署更方便

## 总结
天下无难事 -- 其实很早就看到过，这次尝试自己搭建，其实不麻烦
当然，要真正做成一个内容丰富的个人博客站点，还是要慢慢积累丰富的内容才行。有的大神就纯做技术博客（比如[廖雪峰](https://www.liaoxuefeng.com/)），有的大神则搞一些炫酷的效果（如[云游君的小站](https://www.yunyoujun.cn/about/)），最后都能做得很有知名度。当然，最重要的还是要有核心的技术，博客积累关键还是在于个人的技术积累。
所以，慢慢来吧，共勉