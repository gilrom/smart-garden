#include <Wire.h>

#include "display.h"
#include "parameters.h"
#include "globals.h"
#include <Adafruit_SSD1306.h>
#include <DHT.h>
#include <Adafruit_NeoPixel.h>

float temperature_value;
float humidity_value;
int moisture_value; 
float moisture_percent;
int light_value;
DHT dht11(DHT_PIN, DHT11);
int light_percent;
bool report_wifi_to_pixel;
int tuning_on;
unsigned long display_timeout;

//Neopixel
Adafruit_NeoPixel pixels(NUMPIXELS, NEOPIXEL_PIN, NEO_GRB + NEO_KHZ800);

enum DisplayMode {
  TEMPERATURE,
  HUMIDITY,
  MOISTURE,
  LIGHT
};

Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);
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

void display_temperature() {
	temperature_value = dht11.readTemperature();
	display.setCursor((SCREEN_WIDTH - 12 * 5) / 2, 0);
	display.setTextSize(1);
	display.print("Temperature:");
	display.setCursor((SCREEN_WIDTH - 12 * 5) / 2, (SCREEN_HEIGHT - 16) / 2);
	display.setTextSize(2);
	display.print(temperature_value);
	display.print(" C");
	if (isnan(temperature_value)) 
	{
		pixels.setPixelColor(1, pixels.Color(255, 0, 0));
	}
}

void display_humidity() {
	humidity_value = dht11.readHumidity();
	display.setCursor((SCREEN_WIDTH - 12 * 4) / 2, 0);
	display.setTextSize(1);
	display.print("Humidity:");
	display.setCursor((SCREEN_WIDTH - 11 * 5) / 2, (SCREEN_HEIGHT - 16) / 2);
	display.setTextSize(2);
	display.print(humidity_value);
	display.print(" %");
	if (isnan(humidity_value)) 
	{
		pixels.setPixelColor(1, pixels.Color(255, 0, 0));
	}
}

void display_moisture() {
	const int AirValue = 4095;   //you need to replace this value with Value_1
	const int WaterValue = 0;  
	moisture_value = analogRead(MOISTURE_SENSOR_PIN);
	display.setCursor((SCREEN_WIDTH - 12 * 4) / 2, 0);
	display.setTextSize(1);
	display.print("Moisture:");
	display.setCursor((SCREEN_WIDTH - 13 * 4) / 2, (SCREEN_HEIGHT - 16) / 2);
	display.setTextSize(2);
	moisture_percent = map(moisture_value, AirValue, WaterValue, 0, 100);
	display.print(moisture_percent);
	display.print(" %");
	if (moisture_percent == 100) 
	{
		pixels.setPixelColor(1, pixels.Color(255, 0, 0));
	}
	
}

void display_light(){
	const int DarkValue = 4095;   //you need to replace this value with Value_1
	const int LightValue = 0;  //you need to replace this value with Value_2
	light_value = analogRead(LIGHT_SENSOR_PIN);
	display.setCursor((SCREEN_WIDTH - 12 * 4) / 2, 0);
	display.setTextSize(1);
	display.print("Light level:");
	display.setCursor((SCREEN_WIDTH - 11 * 5) / 2, (SCREEN_HEIGHT - 16) / 2);
	display.setTextSize(2);
	light_percent = map(light_value, DarkValue, LightValue, 0, 100);
	display.print(light_percent);
	display.print(" %");
	if (light_percent == 100) 
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
			report_wifi_to_pixel = false;
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
					display_temperature();
					break;
				case HUMIDITY:
					display_humidity();
					break;
				case MOISTURE:
					display_moisture();
					break;
				case LIGHT:
					display_light();
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

		if ((millis() - display_activated_time > display_timeout) && display_on)
		{
			display.clearDisplay();
			display_on = false;
			display.display();
			report_wifi_to_pixel = true;
		}
		if (moisture_percent == 100 || isnan(humidity_value) || isnan(temperature_value) || light_percent == 100){
			pixels.setPixelColor(1, pixels.Color(255, 0, 0));
			} else {
			pixels.setPixelColor(1, pixels.Color(0, 150, 0));
			}
			if (analogRead(MOISTURE_SENSOR_PIN) == 0){
			pixels.setPixelColor(2, pixels.Color(0, 0, 0));
			}
			pixels.show();
		}
}