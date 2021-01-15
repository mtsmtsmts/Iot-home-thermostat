# Iot-home-thermostat
Using a NodeMCU with ESP8266, HTTP requests, IFTTT, and Google Assistant to control a digital Honeywell thermostat. MCU uses two GPIO pins to control the temperature up and down buttons on the thermostat PCB. 

Warning: modifying your thermostat could expose you to hazardeous voltages, do so at your own risk.

![gif](https://github.com/mtsmtsmts/Iot-home-thermostat/blob/main/ProjectFiles/Hnet-image.gif?raw=true)


### Features
1. Restores state on reset or power out
2. Uses a web based server to store a variable that represents current set point
3. Writes to flash memory two strings that represent the current state: heat on/off and a POR WebIDE flag
4. Can easily use flash memory to store the current set point, I discovered flash memory was accessible during run time after I wrote in the web variable. Can easily change to set all vars in flash memory.
5. If no access to web server after reset set point will init in off state and blink an error to let the user know the set point is not in synch with the thermostat. Can easily change to poll server.
6. Turns off the heat after 1 hour, blinks led very lightly to indicate operation
7. Blinks led for commands and errors
8. Buffers consecutive commands sent and executes first and last commands retreived
9. It is possible to mdify the code so the temperature adjusts to a specific degree. Currently the commands are on(21C)/off(13C)/up(+2C)/down(-2C)/reset(synch 13C)


### GPIO

The GPIO pins are connected to base driven, open collector, NPN BJT transistors. The BJT collectors are each soldered, one to the Up and one to the Down button pads on the Honeywell PCB. The emitter pins are soldered to a common point on the PCB button matrix. A base resistor value is selected to limit base current at <10mA. GPIO14 (nodemcu D5) and GPIO12 (nodemcu D6) are active LOW on reset so they will not trigger the BJTs on reset.

### Timing

There is no feedback loop from the thermostat so the MCU uses timers to closely approximate the length of time to 'push' a button per number of digits that change on the Honeywell LCD. The approximation was determined by filming the buttons pressed and marking the times using software. When a button is held down on the termostat an initial delay of 1.0 second occurs while the thermostat displays the current temperature on the LCD. After the initial delay the digits on the screen change at a rate of 0.183 seconds per degree Celcius at increments of 0.5 degrees. The final result, after much tinkering, is a very close approximation and overshoot/undershoot is rarely seen.

### Power Supply

The final project uses a 9V wallwart with a LM317 regulator set at 3.290V with resistors on hand. Initially the plan was to use the power on board the PCB and from looking at the Honeywell PCB two locations were noted. A 4-pin header that transfers pwr,gnd,signal from the power board to the control board was measured at 6.75Vdc and a 3.3Vdc (500ma?) regulator was found on the control board providing power to a mcu. Neither option turned out to be useful as when loaded in parallel with even a few mA would cause the voltage to dip and the thermostat's mcu to reset. It may be possible to tap off the power board transformer secondary, rectify, and regulate to 3.3v.  

### HTTP Handling

Temperature is controlled one of three ways: manually, using Google Assistant and IFTTT webhooks, or an HTTP GET request. A webIDE provides the ability to modify any of the functions OTA. Much code is credited to different authors and the NodeMCU documentation. The webIDE operates in parallel with the application code because of memory limitations. To load the webIDE a browser sends an http request with a key word, stores the current state of the temperatue, resets the esp8266, and starts the webIDE. The user is able to upload new files, edit files stored in flash, compile files, delete files, and restart the NodeMCU. The IDE will automatically exit after 10 minutes and return the esp8266 to application code, restoring the current state. The current state (on/off and temperature set) is also preserved across power outages. 

### Schematic

![NodeSch](https://github.com/mtsmtsmts/Iot-home-thermostat/blob/main/ProjectFiles/Sch_nodemcu%20thermo.jpg?raw=true)

<p align="center">
    

   
    
<img src="https://github.com/mtsmtsmts/Iot-home-thermostat/blob/main/ProjectFiles/Wemos-D1-Mini.png?raw=true">
</p>



### How To Use
1. Flash firmware to ESP8266 using ESPEasy
2. Modify and flash program code using ESPlorer
3. Configure IFTTT webhooks using the reference in the resources below
4. Create web variable using free webhost listed and upload the PHP file 
5. Use Google Assistant or access using a web browser 


#### To access the application using web browser:
    
   ##### http://`IP_Address`:`Port`/`cmdString:` `Command`

- `IP_Address` = Use your LAN ip set by your router typical: 192.168.0.xx. Outside LAN use your IP address set by your ISP.

- `Port` = The server port (code is set to 8099)

- `cmdString` = Your keyword (default is "webhooks")

- `Command` = Your command. e.g. on the default configuration you can use "on", "off",etc...
 
#### To access the WebIDE using web browser:
   ##### http://`IP_Address`:`Port`/`Command`
 
 - `Command` = string set in code to enable webide (restart in this case). 
 
 LAN Example:
        
        192.168.0.13:8098/webhooks:heaton  or  192.168.0.13:8099/restart
        
#### To access the web stored variable

   ##### http://`Your web host address`/`esppost.php` `?Variable=`

   ##### http://`Your web host address`/`data.html`

- `Your web host` = any web host you decide, I used 000webhost.com

- `esppost.php` = code sends GET request to this file 

- `?Variable=` = text to store data to data.html using php code (`Variable` is Temp in program)

- `data.html` = data stored in cloud

Example:

        http://exampleserver.com/yourdirectory/esppost.php?Temp='on'

# Resources
NodeMCU docs https://nodemcu.readthedocs.io/en/release/

D1 mini docs https://www.wemos.cc/en/latest/d1/d1_mini.html

A simple webIDE https://github.com/joysfera/nodemcu-web-ide 

IFTTT to ESP8266 https://github.com/limbo666/IFTTT_to_ESP8266
### Software

ESPlorer for uploading code using Lua 
https://esp8266.ru/esplorer/ 

Firmware provided from the cloud build
https://nodemcu-build.com/

ESPEasy to flash firmware(provided in dir) 
https://github.com/letscontrolit/ESPEasy

IFTTT app on Android https://ifttt.com/home

Free webhost server to store a single char using PHP
https://www.000webhost.com/


### Hardware

D1mini esp8266 from Aliexpress

2x 2N2222 

LM317 with R2=160R and R1=100R to provide ~3.3V

9V wall wart power adapter

### Datasheets
LM317 https://www.ti.com/lit/gpn/LM317

ESP8266 https://www.espressif.com/sites/default/files/documentation/0a-esp8266ex_datasheet_en.pdf

2N2222 https://www.electroschematics.com/wp-content/uploads/2009/04/2n2222-datasheet.pdf

D1mini https://www.wemos.cc/en/latest/_static/files/sch_d1_mini_v3.0.0.pdf

D1mini pin map https://i2.wp.com/randomnerdtutorials.com/wp-content/uploads/2019/05/ESP8266-WeMos-D1-Mini-pinout-gpio-pin.png?quality=100&strip=all&ssl=1

NodeMCU https://components101.com/development-boards/nodemcu-esp8266-pinout-features-and-datasheet

