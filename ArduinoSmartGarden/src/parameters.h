#ifndef PARAMETERS_H
#define PARAMETERS_H

//Display
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define OLED_RESET    -1  // Reset pin # (or -1 if sharing Arduino reset pin)

//Pins
#define DHT_PIN 25
#define MOISTURE_SENSOR_PIN 35
#define LIGHT_SENSOR_PIN 34
#define BUTTON_PIN 18
#define NEOPIXEL_PIN 26

//Neopixel
#define NUMPIXELS 3

// API key
#define API_KEY "AIzaSyC9cPHW1Vie1sfCNnLh09TpMUO-65_zijo"

// Authorized credentials for Firebase
#define USER_EMAIL "spektorroma@gmail.com"
#define USER_PASSWORD "qwerty123"

// Insert RTDB URLefine the RTDB URL
#define DATABASE_URL "https://database-for-iot-project-default-rtdb.europe-west1.firebasedatabase.app"

//Headline
#define EEPROM_WIFI_NAME_ADDRESS 0
#define EEPROM_WIFI_PASSWORD_ADDRESS 64

//Headline
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

//Threads
#define STACK_SIZE 4096

//Tunning tempo
#define TUNNING_DELAY 1000

//Blinf moisture led
#define BLINK_TIME 200

//Bluthooth credentials
#define DEVICE_NAME "esp_32"

#endif