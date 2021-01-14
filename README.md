# Iot-home-thermostat
Using a NodeMCU with ESP8266, HTTP requests, IFTTT, and Google Assistant to control a digital Honeywell thermostat. MCU uses two GPIO pins to control the temperature up and down buttons on the thermostat PCB. 

## Features
-Restores state on reset or power out

-Uses a web based server to store a variable that represents current set point

-Writes to flash memory two strings that represent the current state: heat on/off and a POR WebIDE flag

-Can easily use flash memory to store the current set point, I discovered flash memory was accessible during run time after I wrote in the web variable. Can easily change to set all vars in flash memory.

-If no access to web server after reset set point will init in off state and blink an error to let the user know the set point is not in synch with the thermostat. Can easily change to poll server.

-Turns off the heat after 1 hour, blinks led very lightly to indicate operation

-Blinks led for commands and errors

-Buffers consecutive commands sent and executes first and last commands retreived


### GPIO

The GPIO pins are connected to base driven, open collector, NPN BJT transistors. The BJT collectors are each soldered, one to the Up and one to the Down button pads on the Honeywell PCB. The emitter pins are soldered to a common point on the PCB button matrix. A base resistor value is selected to limit base current at <2mA.

### Timing

There is no feedback loop from the thermostat so the MCU uses timers to closely approximate the length of time to 'push' a button per number of digits that change on the Honeywell LCD. The approximation was determined by filming the buttons pressed and marking the times using software. When a button is held down on the termostat an initial delay of 1.0 second occurs while the thermostat displays the current temperature on the LCD. After the initial delay the digits on the screen change at a rate of 0.183 seconds per degree Celcius at increments of 0.5 degrees. The final result, after much tinkering, is a very close approximation and overshoot/undershoot is rarely seen.

### Power Supply

The final project uses a 9V wallwart with a LM317 regulator set at 3.290V with resistors on hand. Initially the plan was to use the power on board the PCB and from looking at the Honeywell PCB two locations were noted. A power header pin that transfers pwr,gnd from the power board to the control board was measured at 6.75Vdc and a 3.3Vdc (500ma?) regulator was found on the control board providing power to a mcu. Neither option turned out to be useful as when loaded in parallel with even a few mA would cause the voltage to dip and the thermostat's mcu to reset.

### HTTP Handling

Temperature is controlled one of three ways: manually, using Google Assistant and IFTTT webhooks, or an HTTP GET request. A webIDE provides the ability to modify any of the functions OTA. Much code is credited to different authors. The webIDE operates in parallel with the application code because of memory limitations. An http request with a key word stores the current state of the temperatue, resets the esp8266 and loads the webIDE. The IDE will automatically exit and return the esp8266 to application code, restoring the current state. The current state is also preserved across power outages. 
# Resources
NodeMCU docs https://nodemcu.readthedocs.io/en/release/

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

NodeMCU esp8266 from china

2x 2N2222 

LM317 with R2=160R and R1=100R to provide ~3.3V

9V wall wart power adapter

