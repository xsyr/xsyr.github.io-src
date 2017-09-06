---
layout: post
title: "Make Vim as C/C++ IDE"
date: 2013-09-21 19:38
categories: Vim
tags: Vim
---

## 编辑器之神 ##

一直使用 **Vim** 写代码，有 YouCompleteMe，align，ultisnips，tagbar，nerdtree，SrcExpl，
syntastic，vcscommand，doxygen-support 等大臣辅佐，写起代码来有滋有味。
**Vim** 可以自由的映射快捷键，安装各种插件，所以可以最大程度的把手留在键盘上，不愧是编辑器之神。
曾经用过两三个月的神之编辑器 — **emacs**，它的地位还真不适合我这样的低级别的人去使用，
一是右手小指很受伤（用过的人都知道，**emacs** ctrl 到死），二是个人感觉 **emacs** 的社区
不如 **Vim** 活跃，插件不如 **Vim** 丰富。

<!-- more -->

## 编译安装 Vim ##

使用源码编译安装 Vim 的好处是能够用上最新的补丁。安装很简单：

#### 获取源码 ####
```shell
$ cd $vimsrc
$ hg clone https://vim.googlecode.com/hg/ vim
$ cd vim
$ hg pull
$ hg update
```

#### 编译安装 ####
```shell
$ make uninstall
$ make distclean
$ make uninstall
$ make distclean
$ ./configure --enable-gui=gnome2 \
    --disable-gtktest           \
    --enable-perlinterp=yes     \
    --enable-pythoninterp=yes   \
    --enable-python3interp=yes  \
    --enable-luainterp=yes      \
    --enable-tclinterp=yes      \
    --enable-rubyinterp=yes     \
    --enable-cscope             \
    --enable-multibyte          \
    --enable-xim                \
    --enable-fontset            \
    --enable-sniff              \
    --with-features=huge
$ cd src
$ make
$ sudo make install
$ make clean
```

#### 配置 Vim 参数 ####

配置缩进，高亮搜索，展开 tab 等参数：
```shell
$ gvim ~/.vimrc
```
写入：
{% raw %}
```vim
set tabstop=4
set expandtab
set softtabstop=4
set shiftwidth=4
set incsearch
set hlsearch
set smartindent
set cindent
set nu
set foldcolumn=2
"set textwidth=80
set colorcolumn=80
set laststatus=2
set nocompatible
set showcmd
```

## 安装 NeoBundle 管理各种插件 ##

根据 [NeoBundle](https://github.com/Shougo/neobundle.vim) 的 README 步骤即可。
**.vimrc** 中写入：
```vim
" neobundle {{{
set nocompatible               " Be iMproved

if has('vim_starting')
   set runtimepath+=~/.vim/bundle/neobundle.vim/
endif

call neobundle#rc(expand('~/.vim/bundle/'))

" Let NeoBundle manage NeoBundle
NeoBundleFetch 'Shougo/neobundle.vim'


filetype plugin indent on     " Required!
NeoBundleCheck
" }}}
```
{% endraw %}

这样每次在 **.vimrc**中使用 **NeoBundle** 命令添加插件的源码路径之后，启动 Vim
时 NeoBundle 会自动检测是否有未安装的 插件。
也可以在 Vim 中运行命令 `:NeoBundleInstall`手动安装。

## 安装 YouCompleteMe 实现代码自动补全 ##

[YouCompleteMe](https://github.com/Valloric/YouCompleteMe) 使用 LibClang
进行代码语义补全，而非使用 etags ，所以需要安装 LLVM 和 Clang，最新版本是 3.3。
如果没有安装则在编译安装时会自动下载。
安装的说明已经在项目主页说得很明白了，使用之前要最好先看过 FAQ，
特别是[语义补全缓慢](https://github.com/Valloric/YouCompleteMe#sometimes-it-takes-much-longer-to-get-semantic-completions-than-normal)的问题。

#### 在 .vimrc 中添加安装 YouCompleteMe 的命令 ####

```vim
NeoBundle 'git://github.com/Valloric/YouCompleteMe.git'
```

启动 Vim clone YouCompleteMe 的源码，进入源码的路径执行编译命令：
```shell
$ cd ~/.vim/bundle/YouCompleteMe/
$ mkdir build
$ cd build
$ cmake -G "Unix Makefiles"  -DUSE_SYSTEM_LIBCLANG=ON ~/.vim/bundle/YouCompleteMe/cpp
$ make -j8
```

#### 根据喜好配置快捷键 ####

{% raw %}
```vim
" YouCompleteMe {{{

let g:ycm_min_num_of_chars_for_completion = 1
let g:ycm_confirm_extra_conf = 0
let g:ycm_complete_in_comments_and_strings = 1
let g:ycm_add_preview_to_completeopt = 0
let g:ycm_key_list_select_completion = ['<C-N>', '<Down>']
let g:ycm_key_invoke_completion = '<C-J>'
let g:ycm_filetype_specific_completion_to_diable = { 'cpp' : 1 }
let g:ycm_filetype_whitelist = { 'cpp' : 1, 'c' : 1 }
let g:ycm_filetype_blacklist = {
            \'vim' : 1,
            \'vimshell' : 1,
            \'snippets' : 1,
            \'cmake' : 1,
            \'html' : 1
            \}

set completeopt=menuone,longest
set pumheight=15

" }}}
```
{% endraw %}


## 使用 syntastic 对代码进行语法检查 ##

[syntastic](https://github.com/scrooloose/syntastic) 与 YouComleteMe 结合对语法
进行检查，并将警告和错误信息显示在行号那一栏的左侧。添加下面的命令安装 syntastic：
```vim
$ NeoBundle 'git://github.com/scrooloose/syntastic.git'
```

配置警告和错误提示符号，启用高亮，提示信息的格式：

{% raw %}
```vim
" syntastic {{{
let g:syntastic_error_symbol='✗'
let g:syntastic_warning_symbol='⚠'
let g:syntastic_enable_highlighting = 1
let g:syntastic_stl_format = '[%E{Err: %fe #%e}%B{, }%W{Warn: %fw #%w}]'


" }}}
```
{% endraw %}

## 安装 nerdtree, tagbar, SrcExpl ##

1. [nerdtree](https://github.com/scrooloose/nerdtree) 用来显示文件系统的目录和文件，
可以方便的对目录和文件进行增删查改操作。    
2. [tagbar](https://github.com/majutsushi/tagbar) 使用 [exuberant-ctags](http://ctags.sourceforge.net/) 解析正在编辑的 buffer 的 tag 并显示在侧边栏，这对编写比较长的代码时特别有用。    
3. [SrcExpl](https://github.com/wesleyche/SrcExpl) 显示当前光标所在的 token 的代码。

安装很简单，添加下面的命令到 .vimrc 即可：
```vim
NeoBundle 'git://github.com/majutsushi/tagbar.git'
NeoBundle 'git://github.com/scrooloose/nerdtree.git'
NeoBundle 'git://github.com/wesleyche/SrcExpl.git'git
```

配置各个插件的显示位置，开启和关闭的快捷键：
{% raw %}
```vim
" tagbar {{{
let g:tagbar_left = 1
let g:tagbar_singleclick = 1
let g:tagbar_autoshowtag = 1
let g:tagbar_show_visibility = 1
let g:tagbar_ctags_bin="/usr/local/bin/ctags"
" }}}

" NERDTree {{{
let g:NERDTreeWinPos = 'right'
" }}}

" source explorer {{{
let g:SrcExpl_winHeight = 8
let g:SrcExpl_refreshTime = 300
" // Set "Enter" key to jump into the exact definition context
" let g:SrcExpl_jumpKey = "<ENTER>"

" // Set "Space" key for back from the definition context
" let g:SrcExpl_gobackKey = "<SPACE>"

let g:SrcExpl_pluginList = [
        \ "__Tag_List__",
        \ "_NERD_tree_",
        \ "Source_Explorer"
    \ ]

let g:SrcExpl_searchLocalDef = 1
let g:SrcExpl_isUpdateTags = 0
let g:SrcExpl_updateTagsCmd = "ctags --sort=foldcase -R ."
"let g:SrcExpl_updateTagsKey = "<F12>"

" }}}

" Configure like an IDE {{{

" " Open and close the srcexpl.vim separately
autocmd FileType c,cpp,cmake nmap <Leader>src :SrcExplToggle<CR>

" " Open and close the taglist.vim separately
autocmd FileType c,cpp,cmake nmap <Leader>tag :TagbarToggle<CR>

" " Open and close the NERD_tree.vim separately
"autocmd FileType c,cpp,cmake nmap <Leader>nt  :NERDTreeToggle<CR>
nmap <Leader>nt  :NERDTreeToggle<CR>

" }}}
```
{% endraw %}

## 使用 ultisnips 快速插入代码片段 ##

[ultisnips](https://github.com/SirVer/ultisnips)内置了很多代码片段，并且支持自定义。

安装：
```vim
NeoBundle 'git://github.com/SirVer/ultisnips.git'
```

配置快捷键：
{% raw %}
```vim
" ultisnipptes {{{
let g:UltiSnipsExpandTrigger="<TAB>"
let g:UltiSnipsJumpForwardTrigger="<TAB>"
let g:UltiSnipsJumpBackwardTrigger="<S-TAB>"
let g:UltiSnipsRemoveSelectModeMappings = 0
" }}}
```
{% endraw %}

## 使用 delimitMate 进行括号自动补全 ##

```vim
NeoBundle 'git://github.com/Raimondi/delimitMate.git'
```

配置回车自动缩进等参数：
{% raw %}
```vim
" delimitMate {{{

let delimitMate_expand_cr      = 1
let delimitMate_jump_expansion = 1

" }}}
```
{% endraw %}

## 安装 solarized 主题 ##

```vim
  NeoBundle 'git://github.com/Raimondi/delimitMate.git'
```

使用 dark 背景：

{% raw %}
```vim
" Solarized Colorscheme Config {{{
let g:solarized_termtrans=1    "default value is 0
let g:solarized_hitrail=1    "default value is 0
syntax enable
set background=dark
let g:solarized_termcolors=256
colorscheme solarized
" }}}
```
{% endraw %}

## 安装 VCSCommand 操作各种版本控制系统 ##

```vim
NeoBundle 'git://repo.or.cz/vcscommand'
```

## 使用 doxygen-support 编写 doxygen 注释 ##

```vim
NeoBundle 'https://github.com/vim-scripts/doxygen-support.vim.git'
```

doxygen-support 提供很多全局变量，可以通过修改它们的值实现自定义代码风格。
{% raw %}
```vim
" doxgen {{{
let g:DoxygenToolkit_paramTag_post = " "
let g:load_doxygen_syntax = 1

" }}}
```
{% endraw %}


## 使用 align 格式化代码 ##

[align](http://www.vim.org/scripts/script.php?script_id=294) 能很方便的格式化代码，
是写漂亮代码的好助手。安装过程见链接。使用示例详见这位大叔的网站：http://www.drchip.org/astronaut/vim/align.html#Examples 。


## 我的 .vimrc ##
[.vimrc](https://github.com/xsyr/.vimrc)
