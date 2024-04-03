#include <Arduino.h>
#include <EEPROM.h>

#include <WiFi.h>
#include <WebServer.h>
#include <Preferences.h>
#include <Firebase_ESP_Client.h>
#include <Adafruit_BME280.h>
#include "time.h"
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <DHT.h>
#include <climits>
#include <Adafruit_NeoPixel.h>
#include <NTPClient.h>

//#include <BLEDevice.h>
//#include <BLEServer.h>
//#include <BLEUtils.h>
//#include <BLE2902.h>

#include "parameters.h"
#include "display.h"
#include "globals.h"

//Neopixel
Adafruit_NeoPixel pixels(NUMPIXELS, NEOPIXEL_PIN, NEO_GRB + NEO_KHZ800);

//Temperture
DHT dht11(DHT_PIN, DHT11);

// Provide the token generation process info.
#include "addons/TokenHelper.h"
// Provide the RTDB payload printing info and other helper functions.
#include "addons/RTDBHelper.h"

// Database child nodes
String tempPath = "/temperature";
String humPath = "/humidity";
String moisPath = "/moisture";
String lightPath = "/light_value";
String timePath = "/timestamp";


String displayTimeOut = "/display time out";
String newSettings = "/new settings";
String newGroundSettings = "/new ground settings";
String highGround = "/high_moist";
String lowGround = "/low_moist";
String dryGround = "/dry_value";
String tuning = "/tuning";


// Parent Node (to be updated in every loop)
String parentPath;

FirebaseJson json;
FirebaseJson json_set;
FirebaseJson json_ground;



// Timer variables (send new readings every ...)
unsigned long sendDataPrevMillis = 0;
unsigned long timerDelay = 60000;
unsigned long timerDelay_temp;
bool oneTime = true;

const int AirValue = 4095;   //you need to replace this value with Value_1
const int WaterValue = 0;  //you need to replace this value with Value_2
int minSoilmoisturepercent = 0;
int maxSoilmoisturepercent = 100;
int drySoilmoisturepercent = 0;

const int DarkValue = 4095;   //you need to replace this value with Value_1
const int LightValue = 0;  //you need to replace this value with Value_2
int light_percent = 0;

int settingsChange = 0;
int wifiSettingsChange = 0;
int groundSettingsChange = 0;
int newdisplayTimeWaiting;
int newtimerDelay;

int newHighGround;
int newLowGround;
int newDryGround;


//WIFI
//String WIFI_SSID = "Redmi Note 13 Pro+";
//String WIFI_PASSWORD = "4wq9nyjdiscb5cu";

//String WIFI_SSID = "roi_sasson";
//String WIFI_PASSWORD = "my_password";

//String WIFI_SSID = "Admin";
//String WIFI_PASSWORD = "123456789";



bool serverFirstTime = true;

//struct tm timeinfo;

time_t now;

unsigned long display_timeout = 10000;
int tuning_on = 0;

float temperature_value;
float humidity_value;
int moisture_value; 
float moisture_percent;
int light_value;


volatile bool dataChanged_settings = false;
volatile bool dataChanged_tunning = false;

WebServer server(80);

//BLEServer* pServer = NULL;
//BLECharacteristic* pCharacteristic = NULL;
//bool deviceConnected = false;

String page = "<!DOCTYPE html><html><head><title>Wi-Fi Configuration</title></head><body><h2>Wi-Fi Configuration</h2><form method='post' action='/save'><label for='ssid'>SSID:</label><input type='text' id='ssid' name='ssid'><br><label for='password'>Password:</label><input type='password' id='password' name='password'><br><input type='submit' value='Save'></form></body></html>";
void handleRoot() {
  server.send(200, "text/html", page);
}

void EEPROMWriteString(int address, const String &data) {
  for (int i = 0; i < data.length(); i++) {
    EEPROM.write(address + i, data[i]);
  }
  EEPROM.write(address + data.length(), '\0'); // Null terminator to indicate the end of the string
  EEPROM.commit();
}

void handleSave() {
  ssid_new = server.arg("ssid");
  password_new = server.arg("password");

  // Store Wi-Fi credentials in EEPROM
  EEPROM.begin(512);
  EEPROMWriteString(EEPROM_WIFI_NAME_ADDRESS, ssid_new.c_str());
  EEPROMWriteString(EEPROM_WIFI_PASSWORD_ADDRESS, password_new.c_str());
  EEPROM.end();

  server.send(200, "text/plain", "Wi-Fi credentials saved");
}

void(* resetFunc) (void) = 0;//declare reset function at address 0


void set_sensor_pixels(){
  if (report_wifi_to_pixel){
    if (WiFi.status() != WL_CONNECTED){
      pixels.setPixelColor(0, pixels.Color(255, 0, 0));
    }
  }
}

void set_moisture_pixel(){
  //moisture_percent = moisture_percent = map(moisture_value, 4095, 0, 0, 100);
  if (moisture_percent <= minSoilmoisturepercent){
    pixels.setPixelColor(2, pixels.Color(255, 255, 0));
  }
  if (moisture_percent >= maxSoilmoisturepercent){
    pixels.setPixelColor(2, pixels.Color(0, 0, 150));
  }
  if (moisture_percent < (minSoilmoisturepercent - (minSoilmoisturepercent - drySoilmoisturepercent)/2)){
    pixels.setPixelColor(2, pixels.Color(255, 165, 0));
  }
  if (moisture_percent > minSoilmoisturepercent && moisture_percent < maxSoilmoisturepercent){
    pixels.setPixelColor(2, pixels.Color(0, 150, 0));
  }
  if (moisture_percent == 100){
    pixels.setPixelColor(2, pixels.Color(0, 0, 0));
  }
}

void setup() {

  Serial.begin(115200);

  initWiFi();
  if (WiFi.status() == WL_CONNECTED && first_connection){
    delay(5000);
    getting_server_for_the_first_time();
  }
  pinMode(BUTTON_PIN, INPUT_PULLUP);
  displayInit();
  pixels.begin();
	timeClient.begin();
  dht11.begin();

  #if defined(ESP8266)
  stream_settings.setBSSLBufferSize(2048 /* Rx in bytes, 512 - 16384 */, 512 /* Tx in bytes, 512 - 16384 */);
  stream_tunning.setBSSLBufferSize(2048 /* Rx in bytes, 512 - 16384 */, 512 /* Tx in bytes, 512 - 16384 */);
  #endif

  if (!Firebase.RTDB.beginStream(&stream_settings, databaseSetting.c_str()))
    Serial.printf("stream begin error, %s\n\n", stream_settings.errorReason().c_str());
   if (!Firebase.RTDB.beginStream(&stream_tunning, databaseGroundSetting.c_str()))
    Serial.printf("stream begin error, %s\n\n", stream_tunning.errorReason().c_str());


  Firebase.RTDB.setStreamCallback(&stream_settings, streamCallback, streamTimeoutCallback);
  Firebase.RTDB.setStreamCallback(&stream_tunning, streamCallback, streamTimeoutCallback);

  xTaskCreate(mainLoopDispaly, "mainLoopDispaly", STACK_SIZE, nullptr, 5, nullptr);



}

void loop() 
{

}
