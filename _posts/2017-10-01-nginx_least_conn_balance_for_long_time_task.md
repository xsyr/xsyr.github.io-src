---
layout: post
title: 'nginx least_conn 解决长耗时请求的负载均衡问题'
date: 2017-10-01 17:50:59 +0800
categories: nginx
tags: nginx least_conn
---

我们有一些后端服务器专门用于音视频的处理,这些任务耗时至少在5s,之前用默认的 RR 均衡算法,
总是导致后端服务器堆积大量请求,系统 Load 居高不下. 换了 least_conn 均衡算法之后,
整个后端服务器的负载变得平衡了.

```
upstream fp_calculators {
    least_conn;

    server server1;
    server server2;
}

```

对于此类场景, 基于请求量的负载均衡都不是好办法.如果要做限流, 可以使用 ngx_http_status_module
对每个就客户端和每台后端做连接限制.
```
limit_conn_zone $binary_remote_addr zone=perip:10m;
limit_conn_zone $server_name zone=perserver:10m;

server {
   ...
   limit_conn perip 10;
   limit_conn perserver 100;
}
```
