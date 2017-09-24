---
layout: post
title: 'limitworker - 动态增减worker数量'
date: 2017-09-24 11:13:45 +0800
categories: 编程 go
tags: 编程 go
---

日常工作中时常需要写一些一次性并发执行的任务,但又需要根据相关资源的负载情况对并发任务数进行增减,
通常最简单的方法就是停止进程,修改配置,再重启.这样做有点麻烦的是需要记录当前处理进度,避免再次重启
的时候重复执行已完成的操作.

[limitworker](https://github.com/xsyr/limitworker) 用于动态的控制并发的任务数量,
可通过对 fifo 文件的操作增减并发的任务量.

# demo
```go
package main

import (
    "fmt"
    "time"

    "github.com/xsyr/limitworker"
)

func foo(id int, dying <-chan struct{}) error {
    i := 0
    for {
        quit := false
        select {
            case <-dying: quit = true
        default:
        }
        if quit { break }

        fmt.Printf("[%d] foo\n", id)
        time.Sleep(1 * time.Second)

        i++
        if i == 20 { break }
    }

    fmt.Printf("[%d] foo quit\n", id)
    return nil
}

func main() {
    lw, err := limitworker.New(2, "ctrl", "ctrl.log", foo)
    if err != nil {
        fmt.Println(err)
        return
    }

    lw.Wait()
    lw.Close()
}
```

# 增加并发任务

```bash
$ echo '+2' > ctrl
```

`ctrl.log` 记录并发任务的变化情况:
```
2017/09/24 10:53:43 limitworker.go:206: delta: +2
2017/09/24 10:53:43 limitworker.go:106: [3]+ (running: 3, termErr: 0, termOk: 0)
2017/09/24 10:53:43 limitworker.go:106: [4]+ (running: 4, termErr: 0, termOk: 0)
```

# 减少并发任务
```bash
$ echo '-3' > ctrl
```

`ctrl.log` 记录并发任务的变化情况:
```
2017/09/24 10:53:46 limitworker.go:126: [3]- (running: 3, termErr: 0, termOk: 1)
2017/09/24 10:53:46 limitworker.go:126: [1]- (running: 2, termErr: 0, termOk: 2)
2017/09/24 10:53:46 limitworker.go:126: [2]- (running: 1, termErr: 0, termOk: 3)
2017/09/24 10:53:46 limitworker.go:206: delta: -3
```
