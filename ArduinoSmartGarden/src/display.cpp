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

//Temperture
extern DHT dht11;

#define SAMPLES_NUM 10
#define SAMPLE_DELAY 500

const int DarkValue = 4095;   //you need to replace this value with Value_1
const int LightValue = 0;  //you need to replace this value with Value_2

float average_float(float* float_arr, int len)
{
	float sum = 0;
	float average = 0;
	int nan_ctr = 0;
	for (int i = 0 ; i < len ; i++)
	{
		if (isnan(float_arr[i]))
		{
			nan_ctr++;
		}
		else
		{
			sum += float_arr[i];
		}
	}
	if (len == 0)
	{
		average = 0;
	}
	else
	{
		if (nan_ctr == len)
		{
			average = float_arr[0];
		}
		else
		{
			len = len - nan_ctr;
			average = sum/(float)len;
		}
	}
	return average;
}

int average_int(int* int_arr, int len)
{
	int sum = 0;
	int average = 0;
	for (int i = 0 ; i < len ; i++)
	{
		sum += int_arr[i];
	}
	if (len == 0)
	{
		average = 0;
	}
	else
	{
		average = sum/len;
	}
	return average;
}

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

void set_sensor_pixel()
{
	if (s_moisture > 50 || isnan(s_humidity) || isnan(s_temperature) || s_light == 100)
	{
		pixels.setPixelColor(1, pixels.Color(50, 0, 0));
	} 
	else 
	{
		pixels.setPixelColor(1, pixels.Color(0, 50, 0));
	}
}

void set_moisture_pixel(){
	if (s_moisture <= minSoilmoisturepercent)
	{
		pixels.setPixelColor(2, pixels.Color(30, 30, 0));
	}
	if (s_moisture >= maxSoilmoisturepercent)
	{
		pixels.setPixelColor(2, pixels.Color(0, 0, 50));
	}
	if (s_moisture < (minSoilmoisturepercent - (minSoilmoisturepercent - drySoilmoisturepercent)/2))
	{
		pixels.setPixelColor(2, pixels.Color(50, 10, 0));
	}
	if (s_moisture > minSoilmoisturepercent && s_moisture < maxSoilmoisturepercent)
	{
		pixels.setPixelColor(2, pixels.Color(0, 50, 0));
	}
	if (s_moisture == 100)
	{
		pixels.setPixelColor(2, pixels.Color(0, 0, 0));
	}
}

void display_error(const char* headline)
{
	display.setCursor(0, 1);
	display.setTextSize(2);
	display.print(headline);
	display.print(":");
	
	display.setCursor(30, 35);
	display.setTextSize(3);
	display.print("EER");
}
void display_val(const char* headline, int value, const char* sign)
{
	display.setCursor(0, 1);
	display.setTextSize(2);
	display.print(headline);
	display.print(":");

	display.setCursor(30, 35);
	display.setTextSize(3);
	display.print(value);
	display.print(" ");
	display.print(sign);
}

void HWLoop (void* params)
{
	unsigned long display_activated_time = 0;
	DisplayMode display_mode = TEMPERATURE;
	bool display_on = true;
	int button_pressed = LOW;

	float s_temperature_arr[SAMPLES_NUM];
	float s_humidity_arr[SAMPLES_NUM];
	int s_moisture_arr[SAMPLES_NUM];
	int s_light_arr[SAMPLES_NUM];

	for (int i = 0 ; i < SAMPLES_NUM ; i++)
	{
		s_temperature_arr[i] = dht11.readTemperature();

		s_humidity_arr[i] = dht11.readHumidity();

		int moisture_value = analogRead(MOISTURE_SENSOR_PIN);
		s_moisture_arr[i] = map(moisture_value, 4095, 0, 0, 100);

		int light_value = analogRead(LIGHT_SENSOR_PIN);
		s_light_arr[i] = map(light_value, DarkValue, LightValue, 0, 100);
		delay(100);
	}

	int sampling_index = 0;
	unsigned long last_sampeled = millis();

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

			if (tuning_on == 0)
			{
				display.clearDisplay();
				display.setTextColor(SSD1306_WHITE);
				switch (display_mode) 
				{
					case TEMPERATURE:
						if(isnan(s_temperature))
						{
							display_error("Temp");
						}
						else
						{
							display_val("Temp", s_temperature, "C");
						}
						break;
					case HUMIDITY:
						if(isnan(s_humidity))
						{
							display_error("Humidity");
						}
						else
						{
							display_val("Humidity", s_humidity, "%");
						}
						break;
					case MOISTURE:
						if(s_moisture > 50)
						{
							display_error("Moisture");
						}
						else
						{
							display_val("Moisture", s_moisture, "%");
						}
						break;
					case LIGHT:
						if(s_light == 100)
						{
							display_error("Light");
						}
						else
						{
							display_val("Light", s_light, "%");
						}
						break;
				}
				display.display();
				delay(100);
			}
		}

		if (tuning_on == 1)
		{
			display.clearDisplay();
			display.setCursor(0, 24);
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
		
		if ((millis() - display_activated_time > display_timeout) && display_on)
		{
			display.clearDisplay();
			display_on = false;
			display.display();
			pixelCheck = true;
		}
		
		if ((millis() - last_sampeled) > SAMPLE_DELAY)
		{
			s_temperature_arr[sampling_index] = dht11.readTemperature();

			s_humidity_arr[sampling_index] = dht11.readHumidity();

			int moisture_value = analogRead(MOISTURE_SENSOR_PIN);
			s_moisture_arr[sampling_index] = map(moisture_value, 4095, 0, 0, 100);

			int light_value = analogRead(LIGHT_SENSOR_PIN);
			s_light_arr[sampling_index] = map(light_value, DarkValue, LightValue, 0, 100);


			s_temperature = average_float(s_temperature_arr, SAMPLES_NUM);
			s_humidity = average_float(s_humidity_arr, SAMPLES_NUM);
			s_moisture = average_int(s_moisture_arr, SAMPLES_NUM);
			s_light = average_int(s_light_arr, SAMPLES_NUM);

			sampling_index = (sampling_index+1)%SAMPLES_NUM;
			last_sampeled = millis();
		}

		set_sensor_pixel();
		set_moisture_pixel();
		pixels.show();
	}
}