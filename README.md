# Technion CS IOT Final Project: Smart Garden

## Team Members
- Roman Spector
- Gil Romano
- Roi Sasson

## Project Description
We built this project in the Makers Lab of the Faculty of Computer Science at the Technion. The goal is to create a smart device that enables easy monitoring of garden growing conditions through an application. It involves smart, consistent monitoring of personal garden environmental conditions using an ESP32 board. A compact box houses the board and sensors, connecting to the internet, with a dedicated application and database displaying sensor readings.

## List of Hardware
- ESP32 board
- 3 Neopixel LEDs
- Simple button
- 1.3-inch Monochrome OLED display (128*64 with alternate address)
- Temperature and Humidity sensor (DHT11)
- Light sensor
- Soil Moisture sensor

## Libraries and Versions
- Firebase Arduino Client Library for ESP8266 and ESP32 @ ^4.4.10
- Adafruit BME280 Library @ ^2.2.4
- Adafruit GFX Library @ ^1.11.9
- Adafruit SSD1306 @ ^2.5.9
- DHT sensor library @ ^1.4.6
- Adafruit NeoPixel @ ^1.12.0
- NTPClient @ ^3.2.1

## Folders Contained
- `arduino_smart_garden`: Hardware code
- `smart_garden_app`: Application code with Flutter
- `unit_tests`: Sensors and display tests

## Hardware Connectivity Graph
![Hardware Connectivity Graph](hardware_connectivity_graph.png)