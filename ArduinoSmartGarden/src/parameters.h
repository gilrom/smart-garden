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

// Provide the token generation process info.
#include "addons/TokenHelper.h"
// Provide the RTDB payload printing info and other helper functions.
#include "addons/RTDBHelper.h"

String page = "<!DOCTYPE html><html><head><title>Wi-Fi Configuration</title></head><body><h2>Wi-Fi Configuration</h2><form method='post' action='/save'><label for='ssid'>SSID:</label><input type='text' id='ssid' name='ssid'><br><label for='password'>Password:</label><input type='password' id='password' name='password'><br><input type='submit' value='Save'></form></body></html>";

enum DisplayMode {
  TEMPERATURE,
  HUMIDITY,
  MOISTURE,
  LIGHT
};

//Headline
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

// Database child nodes
String tempPath = "/temperature";
String humPath = "/humidity";
String moisPath = "/moisture";
String lightPath = "/light";
String timePath = "/timestamp";

String wifiPassword = "/wifi password";
String displayTimeOut = "/display time out";
String informationSendTime = "/send information to database";
String newSettings = "/new settings";
String newWifiSettings = "/new wifi settings";
String wifiTroubleCheck = "/wifi wrong name or password";
String newGroundSettings = "/new ground settings";
String wifiName = "/wifi name";
String highGround = "/high ground value";
String lowGround = "/button ground value";
String dryGround = "/dry ground value";
String tuning = "/tuning";

const char* ntpServer = "pool.ntp.org";
const long  gmtOffset_sec = 0;
const int   daylightOffset_sec = 3600;

const int AirValue = 4095;   //you need to replace this value with Value_1
const int WaterValue = 0;  //you need to replace this value with Value_2

const int DarkValue = 4095;   //you need to replace this value with Value_1
const int LightValue = 0; 