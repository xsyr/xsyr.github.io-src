---
layout: post
title: 'Arduino Pro Mini 免复位烧写'
subtitle: ''
date: 2017-09-14 01:01:28 +0800
categories: Arduino IoT
tags:
cover: '/assets/img/arduino-pro-mini.png'
---

自从高中毕业起就放下了电子方面的兴趣，最近心血来潮又捣鼓起来，就买了一个 Arduino Pro Mini 版，
某宝买的8元多，比当年的 89C51单片机便宜多了。Arduino Pro Mini 有好多个版本，我买的是这个版本的：

![arduino-pro-mini](/assets/img/arduino-pro-mini.png)


烧写程序使用 FT232RL 作为 USB转TTL，如下图
![FT232RL](/assets/img/ft232rl.png)

刚拿到手按如下方式将 FT232RL 与 Arduino Pro Mini 连接

| FT232RL引脚 | Arduino Pro Mini引脚 |
| ----------- | -------------------- |
| VCC         | VCC                  |
| GND         | GND                  |
| RX          | TX                   |
| TX          | RT                   |


用 Arduino IDE 自带的 Blink demo程序烧写，总是出现如下错误
```
avrdude stk500_recv() programmer is not responding
avrdude: stk500_getsync(): not in sync: resp=0x00
```
起初以为时板子坏了，测试 FT232RL RX 和 TX 都没问题，换了另一快 Pro Mini 版还是一样错误，
百度得知要在烧写的时候按写复位按钮，但按下按钮的时机很难把握，导致烧写成功率极低。
又尝试加了一根导线链接 FT232RL 的 RTS 和 Pro Mini 版的 RTS 引脚，发现还是不行。
Pro Mini 正常运行或烧写的过程中需要保持 RTS 引脚时高电平，在复位运行或烧写时只需RTS发生``高电平-低电平-高电平``的跳变要连接RTS之后发现Arduino IDE 烧写之后一直都保持在电平，导致烧写不能正常进行。

最后在两个 RTS 引脚之间加一个 6.8uF 的电容解决了这个问题，烧写成功率将近100%。下面波形图显示了
在烧写的时候FT232RL RTS引脚和Pro Mini RTS 引脚的电压变化：

![ft232-rts-arduino-pro-mini-rts-level](/assets/img/ft232-rts-arduino-pro-mini-rts-level.png)

绿色是 FT232RL RTS 引脚电平变化情况，黄色的是 Pro Mini RTS 引脚。可以看到引脚电平变化满足上述要求。`1,2`次点品变化应该是烧写和烧写完之后的复位运行。
