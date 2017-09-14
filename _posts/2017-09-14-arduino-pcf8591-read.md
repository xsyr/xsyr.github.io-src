---
layout: post
title: 'Arduino 读写 PCF8591 芯片'
subtitle: ''
date: 2017-09-14 21:48:44 +0800
categories: Arduino IoT
tags: Arduino IoT PCF8591
cover: '/assets/img/arduino-pcf8591.png'
---

PCF8591 芯片支持4通道 8bit ADC，1通道 8bit DAC，它提供 I2C 接口进行数据读写。

![Arduino-pcf8591](/assets/img/arduino-pcf8591.png)

# 1. 引脚连接

| Arduino | PCF8591 |
| ------- | ------- |
| VCC     | VDD     |
| GND     | AGND    |
| A4(SDA) | SDA     |
| A5(SCL) | SCL     |

# 2. Addr 地址
![PCF8591-addr-byte](/assets/img/pcf8591-addr-byte.png)

上图的板子上已经将 A0,A1,A2 三个引脚接 GND，所以Addr 控制字的 A0, A1, A2 写 000。

# 3. 控制字
![pcf8591-ctrl-byte](/assets/img/pcf8591-ctrl-byte.png)

第7位固定为0, 第6bit 为DAC使能，设置为1时开启。第5,4位控制 ADC 模式。第3位固定为0,
如果第2位为1,则在读取 ADC 时轮流读取各个通道 0->1->2->3->0->1->...。
第1,0位选择通道。

# 4. 读 ADC 结果
```cpp
#include <Wire.h>

#define ADDR 0B1001000
#define EDAC 0B01000000

#define CHAN0  0B00000000
#define CHAN1  0B00000001
#define CHAN2  0B00000010
#define CHAN3  0B00000011

void setup() {
  Wire.begin();
  Wire.setClock(100000); // 设置比特率，测试 100kbps 可以稳定运行。

  Serial.begin(9600); // 设置串口波特率
}


void ADC_Read() {
  Wire.beginTransmission(ADDR); // 发送 Addr 控制字
  Wire.write(CHAN0);            // 选择 通道0
  Wire.endTransmission();

  Wire.requestFrom(ADDR, 1); // 等待 SLAVE(PCF8591)发送ADC值，等待一个字节
  while(Wire.available()) {
    byte v = Wire.read();
    Serial.print(v);
    Serial.print("\n");
  }
}

void loop() {
  ADC_Read();
  delay(200);
}

```
![PCF8591-read-dac](/assets/img/pcf8591-read-dac.png)

# 5. 写 DAC
```cpp
... // 参考上面代码常量定义

#define PI 3.14159265
float n = 0;
void Sin() {
  Wire.beginTransmission(ADDR); // 发送 ADDR 控制字
  Wire.write(EDAC);             // 使能 DAC
  double r  = sin(n * PI) + 1;
  if(r < 0) {
    r = 0;
  }

  byte val = (byte)(r * 2/5 * 256);
  Wire.write(val);  // 写 DAC 值
  Wire.endTransmission();
  n += 0.001;
}


void loop() {
  Sin()
}
```


![pcf8591-write-dac](/assets/img/pcf8591-write-dac.png)
