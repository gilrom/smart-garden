#include <DHT.h>

#include "parameters.h"
#include "sensors.h"

//Temperture
extern DHT dht11;

#define SAMPLES_NUM 10
#define SAMPLE_DELAY 500

const int DarkValue = 4095;   //you need to replace this value with Value_1
const int LightValue = 0;  //you need to replace this value with Value_2

extern float s_temperature;
extern float s_humidity;
extern int s_moisture;
extern int s_light;

float average_float(float* float_arr, int len)
{
	float sum = 0;
	float average = 0;
	int nan_ctr = 0;
	for (int i = 0 ; i < len ; i++)
	{
		if isnan(float_arr[i])
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

void sensorsLoop(void* param)
{
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
	}

	int sampling_index = 0;

    while(1)
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

		delay(SAMPLE_DELAY);
    }
}
