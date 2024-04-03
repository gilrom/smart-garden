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

//Neopixel
#define NUMPIXELS 3
Adafruit_NeoPixel pixels(NUMPIXELS, NEOPIXEL_PIN, NEO_GRB + NEO_KHZ800);

//Temperture
DHT dht11(DHT_PIN, DHT11);

// Provide the token generation process info.
#include "addons/TokenHelper.h"
// Provide the RTDB payload printing info and other helper functions.
#include "addons/RTDBHelper.h"

WiFiUDP ntpUDP;
NTPClient timeClient(ntpUDP);

// Define Firebase objects
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

// Variable to save USER UID
String uid;

// Database main path (to be updated in setup with the user UID)
String databasePath;
String databaseSetting;
String databaseGroundSetting;

String ssid_new ="";
String password_new = "";

const char* ssid = "admin";
const char* password = "admin123";

String WIFI_SSID = "Admin";
String WIFI_PASSWORD = "123456789";

String page = "<!DOCTYPE html><html><head><title>Wi-Fi Configuration</title></head><body><h2>Wi-Fi Configuration</h2><form method='post' action='/save'><label for='ssid'>SSID:</label><input type='text' id='ssid' name='ssid'><br><label for='password'>Password:</label><input type='password' id='password' name='password'><br><input type='submit' value='Save'></form></body></html>";

WebServer server(80);

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


// Parent Node (to be updated in every loop)
String parentPath;

int timestamp;
FirebaseJson json;
FirebaseJson json_set;
FirebaseJson json_ground;

const char* ntpServer = "pool.ntp.org";
const long  gmtOffset_sec = 0;
const int   daylightOffset_sec = 3600;

bool first_connection = true;

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
int lightPercent = 0;

int settingsChange = 0;
int wifiSettingsChange = 0;
int groundSettingsChange = 0;
int newdisplayTimeWaiting;
int newtimerDelay;

int newHighGround;
int newLowGround;
int newDryGround;
bool firstTimeCheckSettings = true;

//WIFI
//String WIFI_SSID = "Redmi Note 13 Pro+";
//String WIFI_PASSWORD = "4wq9nyjdiscb5cu";

//String WIFI_SSID = "roi_sasson";
//String WIFI_PASSWORD = "my_password";

//String WIFI_SSID = "Admin";
//String WIFI_PASSWORD = "123456789";

String newWifiName;
String newWifiPassword;
String WIFI_SSID_temp = "";
String WIFI_PASSWORD_temp = "";
bool wifiTrouble = false;

float Target;

bool serverFirstTime = true;

//struct tm timeinfo;

time_t now;

unsigned long display_timeout = 10000;
bool pixelCheck;
int tuning_on = 0;

float temperature;
float humidity;
int moistureValue; 
float soilmoisturepercent;
int light;


//BLEServer* pServer = NULL;
//BLECharacteristic* pCharacteristic = NULL;
//bool deviceConnected = false;

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

String EEPROMReadString(int address) {
  String data;
  char ch = EEPROM.read(address);
  for (int i = 0; ch != '\0' && i < EEPROM.length(); i++) {
    data += ch;    // Append the character to the string
    ch = EEPROM.read(address + i + 1); // Read the next character
  }
  return data;
}


void getting_server_for_the_first_time (){
  configTime(gmtOffset_sec, daylightOffset_sec, ntpServer);

  // Assign the api key (required)
  config.api_key = API_KEY;

  // Assign the user sign in credentials
  auth.user.email = USER_EMAIL;
  auth.user.password = USER_PASSWORD;

  // Assign the RTDB URL (required)
  config.database_url = DATABASE_URL;

  Firebase.reconnectWiFi(true);
  fbdo.setResponseSize(4096);
    
  // Assign the callback function for the long running token generation task 
  config.token_status_callback = tokenStatusCallback; //see addons/TokenHelper.h

  // Assign the maximum retry of token generation
  config.max_token_generation_retry = 5;

  // Initialize the library with the Firebase authen and config
  Firebase.begin(&config, &auth);

  // Getting the user UID might take a few seconds
  Serial.println("Getting User UID");
  while ((auth.token.uid) == "") {
    Serial.print('.');
    delay(1000);
  }
  // Print user UID
  uid = auth.token.uid.c_str();
  Serial.print("User UID: ");
  Serial.println(uid);

  // Update database path
  databasePath = "/UsersData/" + uid + "/readings";
  databaseSetting = "/UsersData/" + uid + "/settings";
  databaseGroundSetting = "/UsersData/" + uid + "/groundSettings";
  first_connection = false;
}

// Initialize WiFi
void initWiFi() {

  int attempts = 0;

  //EEPROM.begin(512);
  String storedSSID = "";
  String storedPassword = "";
  EEPROM.get(0, Target);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  delay(2000);
  
  if (!isnan(Target) && WiFi.status() != WL_CONNECTED){
    EEPROM.begin(512); // Use the same size as in write
    storedSSID = EEPROMReadString(EEPROM_WIFI_NAME_ADDRESS);
    storedPassword = EEPROMReadString(EEPROM_WIFI_PASSWORD_ADDRESS);
    EEPROM.end();

    Serial.print(storedSSID);
    Serial.print('\n');
    Serial.print(storedPassword);
    Serial.print('\n');


    if (storedSSID.length() > 0 && storedPassword.length() > 0) {
      WIFI_SSID_temp = storedSSID;
      WIFI_PASSWORD_temp = storedPassword;
      Serial.print(WIFI_SSID_temp.c_str()+'\n');
      Serial.print(WIFI_PASSWORD_temp.c_str()+'\n');
    }
    WiFi.begin(WIFI_SSID_temp, WIFI_PASSWORD_temp);
    Serial.print("Connecting to WiFi ..");
  }
  /*
  if (WiFi.status() != WL_CONNECTED){
    WiFi.begin(WIFI_SSID_temp, WIFI_PASSWORD_temp);
    Serial.print("Connecting to WiFi ..");
    delay(10000);
  }
  */
  if (WiFi.status() == WL_CONNECTED){
    WIFI_SSID = WIFI_SSID_temp;
    WIFI_PASSWORD = WIFI_PASSWORD_temp;
    EEPROM.begin(512); // Adjust size as needed
    EEPROMWriteString(EEPROM_WIFI_NAME_ADDRESS, WIFI_SSID);
    EEPROMWriteString(EEPROM_WIFI_PASSWORD_ADDRESS, WIFI_PASSWORD);
    EEPROM.end();
  }
  Serial.println(WiFi.localIP());
  Serial.println();
  /*
  if (WiFi.status() != WL_CONNECTED && serverFirstTime){
      WiFi.softAP(ssid, password);
      Serial.println(WiFi.softAPIP());
      Serial.print("HUI");

      server.on("/", handleRoot);
      server.on("/save", handleSave);

      server.begin();
      server.handleClient();
      WiFi.begin(ssid_new, password_new);
      delay(5000);
        //Serial.print(ssid_new +'\n');
        //Serial.print(password_new + '\n');
      if (WiFi.status() == WL_CONNECTED){
        WIFI_SSID = ssid;
        WIFI_PASSWORD = password;
        Serial.print("Connected");
      }
      WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
      delay(5000);
      if (WiFi.status() == WL_CONNECTED){
        Serial.print("Connected");
      }
      delay(1000);
      serverFirstTime = false;
  }
  */
  if (first_connection && WiFi.status() == WL_CONNECTED){
    getting_server_for_the_first_time();
  }
  //EEPROM.end();
}

void set_sensor_pixels(){
  if (pixelCheck){
    if (analogRead(MOISTURE_SENSOR_PIN) == 0 || isnan(dht11.readHumidity()) || isnan(dht11.readTemperature()) || analogRead(LIGHT_SENSOR_PIN) == 4095){
      pixels.setPixelColor(1, pixels.Color(255, 0, 0));
    } else {
      pixels.setPixelColor(1, pixels.Color(0, 150, 0));
    }
    if (analogRead(MOISTURE_SENSOR_PIN) == 0){
      pixels.setPixelColor(2, pixels.Color(0, 0, 0));
    }
    if (WiFi.status() != WL_CONNECTED){
      pixels.setPixelColor(0, pixels.Color(255, 0, 0));
    }
  }
}

void set_moisture_pixel(){
  float soilmoisturepercent = soilmoisturepercent = map(analogRead(MOISTURE_SENSOR_PIN), 4095, 0, 0, 100);
  if (soilmoisturepercent <= minSoilmoisturepercent){
    pixels.setPixelColor(2, pixels.Color(255, 255, 0));
  }
  if (soilmoisturepercent >= maxSoilmoisturepercent){
    pixels.setPixelColor(2, pixels.Color(0, 0, 150));
  }
  if (soilmoisturepercent < (minSoilmoisturepercent - (minSoilmoisturepercent - drySoilmoisturepercent)/2)){
    pixels.setPixelColor(2, pixels.Color(255, 165, 0));
  }
  if (soilmoisturepercent > minSoilmoisturepercent && soilmoisturepercent < maxSoilmoisturepercent){
    pixels.setPixelColor(2, pixels.Color(0, 150, 0));
  }
  if (soilmoisturepercent == 100){
    pixels.setPixelColor(2, pixels.Color(0, 0, 0));
  }
}

void send_information_to_firebase(){
  json.set(tempPath.c_str(), String(dht11.readTemperature()));
  json.set(humPath.c_str(), String(dht11.readHumidity()));
  
  float moistureValue = analogRead(MOISTURE_SENSOR_PIN);
  Serial.print(moistureValue);
  Serial.print("\n");
  float soilmoisturepercent = map(moistureValue, 4095, 0, 0, 100);

  float light = analogRead(LIGHT_SENSOR_PIN);
  lightPercent = map(light, DarkValue, LightValue, 0, 100);

  json.set(moisPath.c_str(), String(soilmoisturepercent));
  json.set(lightPath.c_str(), String(lightPercent));

  if (Firebase.RTDB.setJSON(&fbdo, parentPath.c_str(), &json)){
    Serial.printf("Set json... %s\n", "ok");
  }
  else{
    Serial.printf("Set json... %s\n", fbdo.errorReason().c_str());
    if (strcmp(fbdo.errorReason().c_str(), "bad request") != 0){
      resetFunc(); //call reset 
    }
  }
}

void check_settings(){
  Firebase.RTDB.getInt(&fbdo, databaseSetting + newSettings, &settingsChange);
  Firebase.RTDB.getInt(&fbdo, databaseSetting + newWifiSettings, &wifiSettingsChange);
  Firebase.RTDB.getInt(&fbdo, databaseGroundSetting + newGroundSettings, &groundSettingsChange);
  Firebase.RTDB.getInt(&fbdo, databaseGroundSetting + tuning, &tuning_on);
  if (settingsChange == 1 || firstTimeCheckSettings){
    Firebase.RTDB.getInt(&fbdo, databaseSetting + displayTimeOut, &newdisplayTimeWaiting);
    Firebase.RTDB.getInt(&fbdo, databaseSetting + informationSendTime, &newtimerDelay);
    display_timeout = newdisplayTimeWaiting;
    timerDelay = newtimerDelay;
    timerDelay_temp = newtimerDelay;
  }
  if (tuning_on == 1 && settingsChange == 0 && !firstTimeCheckSettings && oneTime){
    timerDelay_temp = timerDelay;
    timerDelay = 3000;
    oneTime = false;
  }
  else{
    if (tuning_on == 0 && settingsChange == 0 && !firstTimeCheckSettings && !oneTime){
      timerDelay = timerDelay_temp;
      oneTime = true;
    }
  }
  if (wifiSettingsChange == 1){
    Firebase.RTDB.getString(&fbdo, databaseSetting + wifiName, &newWifiName);
    Firebase.RTDB.getString(&fbdo, databaseSetting + wifiPassword, &newWifiPassword);
    WIFI_SSID_temp = newWifiName;
    WIFI_PASSWORD_temp = newWifiPassword;
  }
  if (groundSettingsChange == 1 || firstTimeCheckSettings){
    Firebase.RTDB.getInt(&fbdo, databaseGroundSetting + highGround, &newHighGround);
    Firebase.RTDB.getInt(&fbdo, databaseGroundSetting + lowGround, &newLowGround);
    Firebase.RTDB.getInt(&fbdo, databaseGroundSetting + dryGround, &newDryGround);
    minSoilmoisturepercent = newLowGround;
    maxSoilmoisturepercent = newHighGround;
    drySoilmoisturepercent = newDryGround;

    json_ground.set(highGround.c_str(), maxSoilmoisturepercent);
    json_ground.set(lowGround.c_str(), minSoilmoisturepercent);
    json_ground.set(dryGround.c_str(), drySoilmoisturepercent);
    json_ground.set(newGroundSettings.c_str(), 0);
    json_ground.set(tuning.c_str(), tuning_on);
  
    if (Firebase.RTDB.setJSON(&fbdo, databaseGroundSetting.c_str(), &json_ground)){
      Serial.printf("Set json... %s\n", "ok");
    }
    else{
      Serial.printf("Set json... %s\n", fbdo.errorReason().c_str());
      if (strcmp(fbdo.errorReason().c_str(), "bad request") != 0){
      resetFunc(); //call reset 
    }
    }
  }
  if (settingsChange == 1 || wifiSettingsChange == 1 || firstTimeCheckSettings || wifiTrouble){
    json_set.set(displayTimeOut.c_str(), int(display_timeout));
    json_set.set(informationSendTime.c_str(), int(timerDelay));
    json_set.set(newSettings.c_str(), 0);
    json_set.set(newWifiSettings.c_str(), 0);
    json_set.set(wifiTroubleCheck.c_str(), wifiTrouble);
    json_set.set(wifiName.c_str(), WIFI_SSID_temp);
    json_set.set(wifiPassword.c_str(), WIFI_PASSWORD_temp);
      //Serial.printf("Set json... %s\n", Firebase.RTDB.setJSON(&fbdo, databaseSetting.c_str(), &json_set) ? "ok" : fbdo.errorReason().c_str());
    if (Firebase.RTDB.setJSON(&fbdo, databaseSetting.c_str(), &json_set)){
      Serial.printf("Set json... %s\n", "ok");
    }
    else{
      Serial.printf("Set json... %s\n", fbdo.errorReason().c_str());
      //resetFunc(); //call reset 
    }
  }
  if (wifiSettingsChange == 1){
    WiFi.begin(WIFI_SSID_temp, WIFI_PASSWORD_temp);
    int attempt = 0;
    while (WiFi.status() != WL_CONNECTED) {
    Serial.print('.');
    
    delay(1000);
    if (attempt < 10){
      attempt++;
    }
    else{
      Serial.print('\n');
      return;
    }
  }
    if (WiFi.status() != WL_CONNECTED){
      Serial.print("hui");
      WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
      Serial.print("hui1");
      delay(10000);
      firstTimeCheckSettings = false;
      wifiTrouble = true;
      return;
    }
    WIFI_SSID = WIFI_SSID_temp;
    WIFI_PASSWORD = WIFI_PASSWORD_temp;
    
    EEPROM.begin(512); // Adjust size as needed
    EEPROMWriteString(EEPROM_WIFI_NAME_ADDRESS, WIFI_SSID);
    EEPROMWriteString(EEPROM_WIFI_PASSWORD_ADDRESS, WIFI_PASSWORD);
    EEPROM.end();
    
  }
  firstTimeCheckSettings = false;

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
  xTaskCreate(mainLoopDispaly, "mainLoopDispaly", STACK_SIZE, nullptr, 5, nullptr);

}

unsigned long getTime() {
  time_t now;
  
  time(&now);
  //Serial.println(&timeinfo, "%A, %B %d %Y %H:%M:%S");
  return now;
}



void loop() {
  set_sensor_pixels();
  set_moisture_pixel();
  // Send new readings to database
  if ((millis() - sendDataPrevMillis > timerDelay || sendDataPrevMillis == 0)){
    sendDataPrevMillis = millis();
    timestamp = getTime();
    parentPath = databasePath + "/" + String(timestamp);
    set_sensor_pixels();
    set_moisture_pixel();
    if (WiFi.status() == WL_CONNECTED && !first_connection){
      timestamp = getTime();
      Serial.print ("time: ");
      Serial.println (timestamp);
      send_information_to_firebase();
      check_settings();
      pixels.setPixelColor(0, pixels.Color(0, 150, 0));
      pixels.show();
    } else{
      if (WiFi.status() != WL_CONNECTED){
        pixels.setPixelColor(0, pixels.Color(255, 0, 0));
        pixels.show();
        //wifi_not_working();
        initWiFi();
        //delay(5000);
      }
      else{
        if(WiFi.status() == WL_CONNECTED && first_connection){
          getting_server_for_the_first_time();
          pixels.setPixelColor(0, pixels.Color(0, 150, 0));
          timestamp = getTime();
          Serial.print ("time: ");
          Serial.println (timestamp);
          send_information_to_firebase();
          check_settings();
        }
      }
    }
  }
  pixels.show();
}
