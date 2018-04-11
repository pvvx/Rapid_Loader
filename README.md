# ESP8266 Rapid Loader V6
Quick start and Support download 48 KB IRAM.

Специальный загрузчик для ESP8266 для ускорения загрузки<br>
и поддержки опции загрузки 48 килобайт IRAM.<br>
При старте отключает такирование RF и вывод<br>
частоты 26 MHz (QCLK) на GPIO0, снижая потребление.<br>
Вывод в logUART у ROM происходит с ожиданием вывода каждого символа.<br>
Во время вывода символов ничего другого не исполняется.<br>  
За счет загрузки ROM всего дного блока в 88 байт<br>
количество символов вывода в logUART на 74880 baud сокращается.<br>
Превый блок в 88 байта ROM грузит очень медленно.<br>
Далее включается XIP и последующая загрузка блоков в IRAM<br>
происходит на максимальной скорости в режиме QIO<br>
Стартовая процедура вызывается с нулевым использованием стека<br>

[График загрузки ESP8266ex c Rapid Loader v3](https://raw.githubusercontent.com/pvvx/Rapid_Loader/master/ESP-01-StartSignals.gif)
[График потребления ESP8266ex c Rapid Loader v6](https://raw.githubusercontent.com/pvvx/Rapid_Loader/master/PowerSDK.gif)

Лог загрузки:<br>
```
 ets Jan  8 2013,rst cause:2, boot mode:(3,6)

load 0x40100000, len 92, room 16 
tail 8
chksum 0x85
csum 0x85
```
где: 'chksum 0x85' это: <br>
Первая цифра контрольной суммы, указывает на частоту работы SPI со Flash (8 -> 80 MHz) <br>
Вторая цифра контрольной суммы, указывает на версию Rapid Loader ( 5 - текущая версия).<br>

Может использоваться для ускорения загрузки любого стандартного <br> 
проекта на ESP8266, путем копирования в начало первого блока кода:<br>
```
copy /b rapid_loader.bin + 00000.bin new00000.bin    
```
 
