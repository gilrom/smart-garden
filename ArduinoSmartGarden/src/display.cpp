#include <Wire.h>

#include "display.h"
#include "parameters.h"
#include <Adafruit_SSD1306.h>
#include <DHT.h>
#include <Adafruit_NeoPixel.h>

enum DisplayMode {
  TEMPERATURE,
  HUMIDITY,
  MOISTURE,
  LIGHT
};

Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);
extern unsigned long display_timeout;
extern bool pixelCheck;
extern int tuning_on;
extern DHT dht11;
extern Adafruit_NeoPixel pixels;
extern float s_temperature;
extern float s_humidity;
extern int s_moisture;
extern int s_light;
extern int minSoilmoisturepercent;
extern int maxSoilmoisturepercent;
extern int drySoilmoisturepercent;

void displayInit()
{

	if(!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) // Address 0x3C for 128x64
	{ 
		Serial.println(F("SSD1306 allocation failed"));
		for(;;);
	}

	display.display();
	delay(2000);
	display.clearDisplay();
}

DisplayMode displaySwitchMode(DisplayMode current) {
	return static_cast<DisplayMode>((current + 1) % 4);
}

void set_moisture_pixel(){
  if (s_moisture <= minSoilmoisturepercent){
    pixels.setPixelColor(2, pixels.Color(255, 255, 0));
  }
  if (s_moisture >= maxSoilmoisturepercent){
    pixels.setPixelColor(2, pixels.Color(0, 0, 150));
  }
  if (s_moisture < (minSoilmoisturepercent - (minSoilmoisturepercent - drySoilmoisturepercent)/2)){
    pixels.setPixelColor(2, pixels.Color(255, 165, 0));
  }
  if (s_moisture > minSoilmoisturepercent && s_moisture < maxSoilmoisturepercent){
    pixels.setPixelColor(2, pixels.Color(0, 150, 0));
  }
  if (s_moisture == 100){
    pixels.setPixelColor(2, pixels.Color(0, 0, 0));
  }
}

void display_val(const char* headline, int value, const char* sign)
{
	display.setCursor(0, 1);
	display.setTextSize(2);
	display.print(headline);
	display.print(":");

	display.setCursor(38, 35);
	display.setTextSize(3);
	display.print(value);
	display.print(sign);
}

void error_pixel_temp() {
	if (isnan(s_temperature)) 
	{
		pixels.setPixelColor(1, pixels.Color(255, 0, 0));
	}
}

void error_pixel_hum() {
	if (isnan(s_humidity)) 
	{
		pixels.setPixelColor(1, pixels.Color(255, 0, 0));
	}
}

void error_pixel_mois() {
	if (s_moisture == 100) 
	{
		pixels.setPixelColor(1, pixels.Color(255, 0, 0));
	}
	
}

void error_pixel_light(){
	if (s_light == 100) 
	{
		pixels.setPixelColor(1, pixels.Color(255, 0, 0));
	}
}

void mainLoopDispaly (void* params)
{
	unsigned long display_activated_time = 0;
	DisplayMode display_mode = TEMPERATURE;
	bool display_on = true;
	int button_pressed = LOW;

	while (1)
	{
		button_pressed = digitalRead(BUTTON_PIN);
	
		if (button_pressed == LOW)
		{
			if (display_on)
			{
				display_mode = displaySwitchMode(display_mode);
			}

			display_on = true;
			display_activated_time = millis();
			pixelCheck = false;
			delay(100); // Optional debounce delay
		}

		if (display_on && tuning_on == 0)
		{
			display.clearDisplay();
			display.setTextSize(1);
			display.setTextColor(SSD1306_WHITE);

			switch (display_mode) 
			{
				case TEMPERATURE:
					display_val("Temp", s_temperature, "C");
					error_pixel_temp();
					break;
				case HUMIDITY:
					display_val("Air Hum", s_humidity, "%");
					error_pixel_hum();
					break;
				case MOISTURE:
					display_val("Soil Moist", s_moisture, "%");
					error_pixel_mois();
					break;
				case LIGHT:
					display_val("Light", s_light, "%");
					error_pixel_light();
					break;
			}
			display.display();
			delay(100);
		}
		else
		{
			if (tuning_on == 1)
			{
				display.clearDisplay();
				display.setCursor((SCREEN_WIDTH - 20 * 3) / 2, (SCREEN_HEIGHT - 16) / 2);
				display.setTextSize(2);
				display.setTextColor(SSD1306_WHITE);
				display.print("Tuning...");
				display.display();
			}
			else
			{
				display.clearDisplay();
				display.display();
			}
		}
		/*
		if ((millis() - display_activated_time > display_timeout) && display_on)
		{
			display.clearDisplay();
			display_on = false;
			display.display();
			pixelCheck = true;
		}
		*/
		if (s_moisture == 100 || isnan(s_humidity) || isnan(s_temperature) || s_light == 100){
			pixels.setPixelColor(1, pixels.Color(255, 0, 0));
			} else {
			pixels.setPixelColor(1, pixels.Color(0, 150, 0));
			}
			if (s_moisture == 100){
			pixels.setPixelColor(2, pixels.Color(0, 0, 0));
			}
		set_moisture_pixel();
		pixels.show();
	}
}