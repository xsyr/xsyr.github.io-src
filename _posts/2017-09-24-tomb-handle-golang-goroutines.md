---
layout: post
title: 'tomb - 管理 goroutine'
date: 2017-09-24 14:53:48 +0800
categories: 编程 golang
tags: tomb
---

日常开发中,最常见的就是处理并发问题,比如要完成一个业务操作,需要读取多个数据源(Map),
得到所有数据之后再进行汇总(Reduce)操作,最终完成业务操作.如果某个数据源读取操作失败,
整个业务操作当失败处理.

例如,需要同时拿到 redis 和 mysql 的数据才能继续业务流程,常见写法如下:
```go
func queryRedisOld(value *int, err chan error) {
    if value == nil {
        err<-fmt.Errorf("null pointer")
        return
    }
    *value = 10
    err<-nil
}

func queryMySQLOld(value *int, err chan error) {
    if value == nil {
        err<-fmt.Errorf("null pointer")
        return
    }
    *value = 20
    err<-nil
}

func oldFashion() {
    var r, m int
    errR, errM := make(chan error), make(chan error)
    go queryRedisOld(&r, errR)
    go queryMySQLOld(&m, errM)

    if err := <-errR; err != nil {
        fmt.Println(err)
        return
    }

    if err := <-errM; err != nil {
        fmt.Println(err)
        return
    }

    fmt.Printf("r = %d, m = %d\n", r, m)
}

func main() {
    oldFashion()
}
```

# tomb
[tomb](https://github.com/xsyr/tomb) 能更优雅的处理这种情况, `tomb.Gos(...)`能并行执行多个
操作:
```go
package main

import (
    "fmt"

    "github.com/xsyr/tomb"
)

func queryRedis(value *int) error {
    if value == nil {
        return fmt.Errorf("null pointer")
    }
    *value = 10
    return nil
}

func queryMySQL(value *int) error {
    if value == nil {
        return fmt.Errorf("null pointer")
    }
    *value = 20
    return nil
}

func newFashion() {
    var t tomb.Tomb

    var r, m int
    t.Gos(func() error { return queryRedis(&r) },
          func() error { return queryMySQL(&m) })
    err := t.Wait()
    if err != nil {
        fmt.Println(err)
    } else {
        // do something ...
        fmt.Printf("r = %d, m = %d\n", r, m)
    }
}

func main() {
    newFashion()
}
```

# tomb.Go(...) 的坑
`tomb.Go(...)` 实现如下:
```go
func (t *Tomb) Go(f func() error) {
	t.init()
	t.m.Lock()
	defer t.m.Unlock()
	select {
	case <-t.dead:
		panic("tomb.Go called after all goroutines terminated")
	default:
	}
	t.alive++
	go t.run(f)
}
```
留意 `panic`这句, 接口文档也说了`Calling the Go method after all tracked goroutines return causes a runtime panic`,但在实际编码过程中,根本就很难保证在调用 `tomb.Go(...)`的时候之前提交的操作没有完全执行完,所以在使用这个库的时候会存在 `panic` 的风险. 虽然可以用 `recover` 捕获`panic`,但会增加代码量和代码复杂度.所以库里新增 `tomb.Gos(...)` 接口,用于同时提交多个并发执行的操作,保证不会出现 `panic`:
```go

// Gos runs multiple f at a time and tracks its termination.
func (t *Tomb) Gos(fs ...Fn) {
	t.init()
	t.m.Lock()
	defer t.m.Unlock()
	select {
	case <-t.dead:
		panic("tomb.Go called after all goroutines terminated")
	default:
	}

    for _, f := range fs {
        t.alive++
        go t.run(f)
    }
}
```
