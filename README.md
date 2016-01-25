# ESP8266 Rapid Loader V4
Quick start and Support download 48 KB IRAM.

Специальный загрузчик для ESP8266 для ускорения загрузки<br>
и поддержки опции загрузки 48 килобайт IRAM.<br>
С версии 4 сразу при старте отключает вывод частоты 26 MHz (QCLK) на GPIO0.<br>

[График загрузки ESP8266ex c Rapid Loader](https://raw.githubusercontent.com/pvvx/Rapid_Loader/master/ESP-01-StartSignals.gif)

Лог загрузки:<br>
```
 ets Jan  8 2013,rst cause:2, boot mode:(3,6)

load 0x40100000, len 108, room 16 
tail 8
chksum 0x84
csum 0x84
```
где: 'chksum 0x84' это: <br>
Первая цифра контрольной суммы, указывает на частоту работы SPI со Flash.<br>
Вторая цифра контрольной суммы, указывает на версию Rapid Loader.<br>

Может использоваться для ускорения загрузки любого стандартного <br> 
проекта на ESP8266, путем копирования в начало первого блока кода:<br>
```
copy /b rapid_loader.bin + 00000.bin new00000.bin    
```

 
