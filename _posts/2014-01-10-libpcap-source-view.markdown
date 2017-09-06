---
layout: post
title: "libpcap 源码简析"
date: 2014-01-10 21:35
comments: true
categories: ["Programming", "C"]
---

前面在实现 [1588 报文转发](http://xinsuiyuer.github.io/blog/2014/01/05/ptpproxy/)时使用了 RAW Soket，公司要求组网时要能支持 1000台
1588 客户端，所以需要尽量提高转发程序的性能。目前采取如下措施：   

1. 使用 libpcap 代替 Raw Socket，在 CONFIG_PACKET_MMAP 参数开启的内核中可以使用
 Memory-mapped I/O 提高性能。
2. 只有本客户端对应的 Delay_Resp 报文才会转发，并丢弃其他客户端发出的 Req 报文。
3. 客户端在收到 Sync 报文之后，随机选择一个时间延时发出 Delay_Req 报文，这样可以
减轻主时钟服务器的并发压力，也可以减少转发程序的压力。


libpcap 1.5.2 的使用步骤如下：   

1. pcap_create() 创建一个 handle
2. pcap_activate(handle)
2. pcap_setfilter() 设置过滤规则
3. pcap_loop(), pcap_dispatch(), pcap_next(), pcap_next_ex() 读取报文。
4. pcap_inject(), pcap_sendpacket() 发送数据
5. pcap_close(handle)

<!-- more -->

几个函数的调用过程：
```c
pcap_create()
    pcap_create_interface()
        pcap_create_common()
        activate_op = pcap_activate_linux;



pcap_activate(handle)
    p->activate_op(handle)





pcap_activate_linux(handle)
	handle->inject_op       = pcap_inject_linux;
	handle->setfilter_op    = pcap_setfilter_linux;
	handle->setdirection_op = pcap_setdirection_linux;
	handle->set_datalink_op = pcap_set_datalink_linux;
	handle->getnonblock_op  = pcap_getnonblock_fd;
	handle->setnonblock_op  = pcap_setnonblock_fd;
	handle->cleanup_op      = pcap_cleanup_linux;
	handle->read_op         = pcap_read_linux;
	handle->stats_op        = pcap_stats_linux;


    activate_new(handle)
        socket(PF_PACKET, SOCK_RAW, htons(ETH_P_ALL))
    activate_mmap(handle)
        handle->read_op = pcap_read_linux_mmap_v1/2/3;


        /// 如果调用 pcap_next_ex() 或者 pcap_next()，则需要在 pcap_loop() 的回调函数中
        /// 将 MMAP 的 frame 复制到此 buffer中。因此这和直接调用 recv，recvfrom 一样，要进行一次内存拷贝，
        /// 这失去了 MMAP 的优势。
        handle->priv->oneshot_buffer = malloc(handle->snapshot);
        create_ring(handle)

            /// 计算 环形缓冲区 的总大小
            /// 环形缓冲区由多个块（Block）组成，每个 Block 又由 帧（Frame）组成。
            /// 这些帧会映射到实际的物理内存中，内核和用户进程共享此内存块。
            handlep->mmapbuflen = req.tp_block_nr * req.tp_block_size;
            handlep->mmapbuf = mmap(0, handlep->mmapbuflen, PROT_READ|PROT_WRITE, MAP_SHARED, handle->fd, 0);



pcap_loop(handle, callback, ...)
    while(condition) {
        handle->read_op(handle, ...)
            pcap_read_linux_mmap_v1(handle, ...)
                pcap_wait_for_frames_mmap(handle)
                    poll({ handle->fd })

                /// 内核将收到数据填充到 Frame，并将 tpacket_hdr 的 tp_status 标记为
                /// TP_STATUS_USER 。
                pcap_get_ring_frame(handle, TP_STATUS_USER)

                /// 将 Frame 传给回调函数。相对于 recv，少了一次内存复制。
                pcap_handle_packet_mmap(callback)

                /// 将 Frame 标记为 TP_STATUS_KERNEL，告知内核可以用来接收数据了。
                h.h1->tp_status = TP_STATUS_KERNEL;
    }

pcap_dispatch(handle, ...)
    handle->read_op(handle, ...)


pcap_next(handle, ...)
    pcap_dispatch(handle, ...)


pcap_next_ex(handle, ...)
    handle->read_op(handle, ...)


pcap_inject(handle, ...)
    handle->inject_op(data)
        pcap_inject_linux(data)
            send(handle->fd, data)



```
