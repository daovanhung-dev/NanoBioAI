# 产品链接

[微雪电子 ESP32-C6-Touch-AMOLED-1.32](https://www.waveshare.net/shop/ESP32-C6-Touch-AMOLED-1.32.htm)

# 编译配置命令

**克隆工程**

```bash
git clone https://github.com/daovanhung-dev/NanoBioAI.git
```

**进入工程**

```bash
cd NanoBioAI/iot/nabi-esp32
```

**配置编译目标为 ESP32C6**

```bash
idf.py set-target esp32c6
```

**打开 menuconfig**

```bash
idf.py menuconfig
```

**选择板子**

```bash
Nabi Assistant -> Board Type -> Waveshare ESP32-C6-Touch-AMOLED-1.32
```

**编译**

```ba
idf.py build
```

**下载并打开串口终端**

```bash
idf.py build flash monitor
```

