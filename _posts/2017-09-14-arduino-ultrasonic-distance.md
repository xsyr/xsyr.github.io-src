---
layout: post
title: 'Arduino 超声波测距'
subtitle: ''
date: 2017-09-14 22:40:31 +0800
categories: Arduino IoT
tags: Arduino IoT
cover: '/assets/img/arduino-ultrasonic-distance.png'
---

超声波通过发送一束超声波，再计算接收时的时间间隔 sec，就可以通过公式
距离 = (sec * 340)/2 计算出来。不过实际上温度，湿度都会造成结果误差，但在精度要求不高的场合，
简单的计算就可以满足。超声波收发模块：
![Arduino-ultrasonic-distance](/assets/img/arduino-ultrasonic-distance.png)

# 1. 电路引脚连接
超声波模块包含4个引脚，分别为 Vcc, Trig, Echo, GND，给 Trig 引脚一个10uS以上的低电平脉冲信号，
Echo 收到信号后会输出高电平，计算高电平的时间就是间隔时间。
这里计算间隔时间通过中断来计算，即低电平变为高电平的时候记下时间 t1, 高电平变为低电平的时候几下时间
t2，时间间隔 = t2 - t1。采用中断而不使用轮询是为了提高时间精度。

Arduino 只提供2,3两个可中断的引脚，这里使用2引脚监听 Echo 的电平变化，3引脚连接 Echo 触发信号．

| Arduino | 超声波模块 |
| ------- | ---------- |
| Vcc     | Vcc        |
| GND     | GND        |
| 2       | Echo       |
| 3       | Trig       |

# 测距代码
```cpp

unsigned long elapsed;

void echo() {
  noInterrupts();
  int s = digitalRead(2);
  if(s == HIGH) {
    elapsed = micros();           // Echo 变为高电平时记下时间　t1
  } else {
    elapsed = micros() - elapsed; // Echo 变为低电平时记下时间　t2
  }

  interrupts();
}

// the setup function runs once when you press reset or power the board
void setup() {

  // 引脚３默认为低电平，15uS的高电平脉冲会触发发送测距超声包．
  pinMode(3, OUTPUT);
  digitalWrite(3, LOW);

  // 引脚２可中断，电平跳变会触发中断
  pinMode(2, INPUT);
  attachInterrupt(digitalPinToInterrupt(2), echo, CHANGE);

  Serial.begin(9600);

  elapsed = 0;
}

// the loop function runs over and over again forever
void loop() {
  while(true) {

    // 发出 15微秒的脉冲.
    digitalWrite(3, HIGH);
    delayMicroseconds(15);
    digitalWrite(3, LOW);

    if (Serial) {
      float sec = float(elapsed)/1000000;
      float distance = (sec * 340/2)*100; // *100 米转换为厘米
      Serial.print(sec*1000, 3);
      Serial.print(" ms, ");
      Serial.print(distance, 2);
      Serial.print(" cm\n");
    }

    digitalWrite(LED_BUILTIN, HIGH);
    delay(500);
    digitalWrite(LED_BUILTIN, LOW);
    delay(500);
  }
}
```

## Arduino 测试结果
![arduino-ultrasonic-tty](/assets/img/arduino-ultrasonic-tty.png)

##　逻辑分析仪分析结果

这里看到的　Arduino 测到的时间间隔是　7.3ms 左右，下面是逻辑分析仪抓取结果：

![arduino-ultrasonic-login-analyze](/assets/img/arduino-ultrasonic-login-analyze.png) Echo 高电平持续时间约　7.3ms，和　Arduino 测到的结果时很相近的，可见用中断的方式可以得到
比较精确的结果．
