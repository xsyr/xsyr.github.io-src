---
layout: post
title: 'VIM 安装 Golang 插件'
subtitle: ''
date: 2017-09-16 15:23:28 +0800
categories: 杂记
tags: 杂记
cover: '/assets/img/vim-golang-plugin.png'
---

# 1. 安装 syntastic
 参考 [Make Vim as C/C++ IDE](https://xsyr.github.io/vim/2013/09/21/make-vim-as-c-plus-plus-ide.html)

# 2. 安装 golint
```bash
go get -u github.com/golang/lint/golint
```

# 3. 配置  syntastic
```
$ vim .vimrc
...
let g:syntastic_go_checkers = ['go', 'golint']
...
```

完成!


![vim-golang-plugin](/assets/img/vim-golang-plugin.png)
