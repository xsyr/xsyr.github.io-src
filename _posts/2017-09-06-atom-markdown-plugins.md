---
layout: post
title: 'Atom + Github Pages markdown 插件安装'
subtitle: ''
date: 2017-09-06 21:26:42 +0800
categories: markdown
tags: markdown
cover: '/assets/img/atom-markdown-editor-effect.png'
---

在 VIM 里写 markdown 真的不太方便，特别是要贴图的时。Atom 的几个插件可以帮助我们快捷的写
markdown文档。这里介绍几个：
1. `markdown-preview-plus` 用于在 Atom 生成预览
2. `markdown-imgage-paste` 用于在 Atom 中`ctrl+v` 粘贴图片
3. `language-markdown`     用于编程语言高亮
4. `markdown-scroll-sync`  用于同步滚动预览窗口
5. `markdown-table-editor`  用于编辑表格

Github Pages 是用 jekyll 生成的静态网页，所以会遵循jekyll的布局，通常 markdown 文档
保存在 `_post` 目录下，生成的静态网页在 `_site` 下，markdown 中引用的图片一般放到
jekyll根目录的 `assets/img` 中，所以本文用到的 `markdown-preview-plus` 和 `markdown-imgage-paste` 做了适当修改，一是 ctrl+v 粘贴的图片自动保存到`assets/img`下，
`markdown-preview-plus`生成预览时会到 `assets/img`下找到对应的图片。
效果图
![atom-markdown-editor-effect](/assets/img/atom-markdown-editor-effect.png)

# 1. 安装 markdown-preview-plus + markdown-imgage-paste

```shell
$ apm install xsyr/markdown-img-paste
$ apm install xsyr/markdown-preview-plus
```

## markdown-preview-plus 开启 jekyll 支持功能
![markdown-preview-plus-enable](/assets/img/markdown-preview-plus-enable.png)

## markdown-imgage-paste 开启 jekyll 支持功能
![markdown-imgage-paste-enable](/assets/img/markdown-imgage-paste-enable.png)
其中`Jekyll image folder`为相对jekyll根目录用于保存图片的文件夹.


# 2. 安装其他插件
```shell
$ apm install language-markdown
$ apm install markdown-scroll-sync
$ apm install markdown-table-editor
```
