#include <Wire.h>

#include "display.h"
#include "parameters.h"

enum DisplayMode {
  TEMPERATURE,
  HUMIDITY,
  MOISTURE,
  LIGHT
};

dafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

void 
{

	if(!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) // Address 0x3C for 128x64
	{ 
		Serial.println(F("SSD1306 allocation failed"));
		for(;;);
	}

	display.display();
	delay(2000);
	display.clearDisplay();
	pixels.begin();
	timeClient.begin();
}

DisplayMode displaySwitchMode(DisplayMode current) {
	return static_cast<DisplayMode>((current + 1) % 4);
}

void display_temperature() {
	temperature = dht11.readTemperature();
	display.setCursor((SCREEN_WIDTH - 12 * 5) / 2, 0);
	display.setTextSize(1);
	display.print("Temperature:");
	display.setCursor((SCREEN_WIDTH - 12 * 5) / 2, (SCREEN_HEIGHT - 16) / 2);
	display.setTextSize(2);
	display.print(temperature);
	display.print(" C");
	if (isnan(temperature)) 
	{
		pixels.setPixelColor(1, pixels.Color(255, 0, 0));
	} else 
	{
		pixels.setPixelColor(1, pixels.Color(0, 150, 0));
	}
}

void display_humidity() {
	humidity = dht11.readHumidity();
	display.setCursor((SCREEN_WIDTH - 12 * 4) / 2, 0);
	display.setTextSize(1);
	display.print("Humidity:");
	display.setCursor((SCREEN_WIDTH - 11 * 5) / 2, (SCREEN_HEIGHT - 16) / 2);
	display.setTextSize(2);
	display.print(humidity);
	display.print(" %");
	if (isnan(humidity)) 
	{
		pixels.setPixelColor(1, pixels.Color(255, 0, 0));
	} 
	else 
	{
		pixels.setPixelColor(1, pixels.Color(0, 150, 0));
	}
}

void display_moisture() {
	moistureValue = analogRead(MOISTURE_SENSOR_PIN);
	display.setCursor((SCREEN_WIDTH - 12 * 4) / 2, 0);
	display.setTextSize(1);
	display.print("Moisture:");
	display.setCursor((SCREEN_WIDTH - 13 * 4) / 2, (SCREEN_HEIGHT - 16) / 2);
	display.setTextSize(2);
	soilmoisturepercent = map(moistureValue, AirValue, WaterValue, 0, 100);
	display.print(soilmoisturepercent);
	display.print(" %");
	if (moistureValue == 0) 
  	{
		pixels.setPixelColor(1, pixels.Color(255, 0, 0));
	} 
	else 
	{
		pixels.setPixelColor(1, pixels.Color(0, 150, 0));
	}
}

void display_light(){
	light = analogRead(LIGHT_SENSOR_PIN);
	display.setCursor((SCREEN_WIDTH - 12 * 4) / 2, 0);
	display.setTextSize(1);
	display.print("Light level:");
	display.setCursor((SCREEN_WIDTH - 11 * 5) / 2, (SCREEN_HEIGHT - 16) / 2);
	display.setTextSize(2);
	lightPercent = map(light, DarkValue, LightValue, 0, 100);
	display.print(lightPercent);
	display.print(" %");
	if (lightPercent == 100)
	{
		pixels.setPixelColor(1, pixels.Color(255, 0, 0));
	} 
	else 
	{
		pixels.setPixelColor(1, pixels.Color(0, 150, 0));
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
		button_pressed = digitalRead(BUTTON_PIN)
	
		if (button_pressed == LOW)
		{
			if (display_on)
			{
				display_mode = displaySwitchMode();
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
				display.setTextSize(1);
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

		if ((millis() - display_activated_time > displayTimeWaiting) && display_on)
		{
			display.clearDisplay();
			display_on = false;
			display.display();
			pixelCheck = true;
		}
	}
}