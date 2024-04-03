// This file contains all the variables that should be knowen to all other files

#ifndef DISPLAY_H
#define DISPLAY_H

#include <Adafruit_SSD1306.h>
#include <DHT.h>

extern unsigned long display_timeout;
extern bool report_wifi_to_pixel;
extern int tuning_on;
extern DHT dht11;
extern Adafruit_NeoPixel pixels;
extern float temperature_value;
extern float humidity_value;
extern int moisture_value; 
extern int moisture_percent;
extern int light_value;
extern int light_percent;

#endif