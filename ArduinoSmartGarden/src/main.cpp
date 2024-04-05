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
#include "hardware.h"

//Neopixel
#define NUMPIXELS 3
Adafruit_NeoPixel pixels(NUMPIXELS, NEOPIXEL_PIN, NEO_GRB + NEO_KHZ800);

//Temperture
DHT dht11(DHT_PIN, DHT11);

float s_temperature = 0;
float s_humidity = 0;
int s_moisture = 0;
int s_light = 0;

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
FirebaseData stream_settings;
FirebaseData stream_tunning;

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
String highGround = "/high_moist";
String lowGround = "/low_moist";
String dryGround = "/dry_value";
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
unsigned long timerDelay = 10000;
unsigned long timerDelay_temp;
bool oneTime = true;

int minSoilmoisturepercent = 0;
int maxSoilmoisturepercent = 100;
int drySoilmoisturepercent = 0;

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

volatile bool dataChanged_settings = false;
volatile bool dataChanged_tunning = false;

bool streamConnect = false;

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
  delay(5000);
  Serial.print(WIFI_SSID);
  Serial.print("\n");
  Serial.print(WIFI_PASSWORD);

  if (WiFi.status() != WL_CONNECTED)
  {
    Serial.print("NOT CONNECTED!");
  }
  
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
    delay(5000);
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

void set_wifi_pixels(){
  if (pixelCheck){
    if (WiFi.status() != WL_CONNECTED){
      pixels.setPixelColor(0, pixels.Color(50, 0, 0));
    }
  }
}


void streamCallback(FirebaseStream data)
{
  Serial.printf("stream path, %s\nevent path, %s\ndata type, %s\nevent type, %s\n\n",
                data.streamPath().c_str(),
                data.dataPath().c_str(),
                data.dataType().c_str(),
                data.eventType().c_str());
  printResult(data); // see addons/RTDBHelper.h
  Serial.println();

  // This is the size of stream payload received (current and max value)
  // Max payload size is the payload size under the stream path since the stream connected
  // and read once and will not update until stream reconnection takes place.
  // This max value will be zero as no payload received in case of ESP8266 which
  // BearSSL reserved Rx buffer size is less than the actual stream payload.
  Serial.printf("Received stream payload size: %d (Max. %d)\n\n", data.payloadLength(), data.maxPayloadLength());

  // Due to limited of stack memory, do not perform any task that used large memory here especially starting connect to server.
  // Just set this flag and check it status later.
  if (data.streamPath() == databaseSetting)
    dataChanged_settings = true;
  else
    dataChanged_tunning = true;
}

void streamTimeoutCallback(bool timeout)
{
  if (timeout)
    Serial.println("stream timed out, resuming...\n");

  if (!stream_settings.httpConnected())
    Serial.printf("error code: %d, reason: %s\n\n", stream_settings.httpCode(), stream_settings.errorReason().c_str());
  if (!stream_tunning.httpConnected())
    Serial.printf("error code: %d, reason: %s\n\n", stream_tunning.httpCode(), stream_tunning.errorReason().c_str());
}

void send_information_to_firebase(){
  json.set(tempPath.c_str(), String(s_temperature));
  json.set(humPath.c_str(), String(s_humidity));
  json.set(moisPath.c_str(), String(s_moisture));
  json.set(lightPath.c_str(), String(s_light));

  if (Firebase.RTDB.setJSON(&fbdo, parentPath.c_str(), &json)){
    Serial.printf("Set json... %s\n", "ok");
  }
  else{
    Serial.printf("Set json... %s\n", fbdo.errorReason().c_str());
    if (strcmp(fbdo.errorReason().c_str(), "bad request") != 0 && strcmp(fbdo.errorReason().c_str(), "response payload read timed out") != 0){
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
    display_timeout = newdisplayTimeWaiting * 1000;
    timerDelay = newtimerDelay * 1000;
    timerDelay_temp = newtimerDelay * 1000;
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
      if (strcmp(fbdo.errorReason().c_str(), "bad request") != 0 && strcmp(fbdo.errorReason().c_str(), "response payload read timed out") != 0){
      resetFunc(); //call reset 
    }
    }
  }
  if (settingsChange == 1 || wifiSettingsChange == 1 || firstTimeCheckSettings){
    display_timeout = display_timeout/1000;
    json_set.set(displayTimeOut.c_str(), int(display_timeout));
    display_timeout = display_timeout*1000;
    timerDelay = timerDelay/1000;
    json_set.set(informationSendTime.c_str(), int(timerDelay));
    timerDelay = timerDelay*1000;
    Serial.print(timerDelay);
    Serial.print('\n');
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
  Serial.print("HUI\n");

}

void connect_to_stream(){
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

}

void setup() {
  if (!streamConnect)
  pinMode(MOISTURE_SENSOR_PIN, INPUT_PULLDOWN);

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

  xTaskCreate(HWLoop, "HWLoop", STACK_SIZE, nullptr, 5, nullptr);
}

unsigned long getTime() {
  time_t now;
  
  time(&now);
  //Serial.println(&timeinfo, "%A, %B %d %Y %H:%M:%S");
  return now;
}


void loop() {
  set_wifi_pixels();
  pixels.show();
  if (WiFi.status() == WL_CONNECTED && !streamConnect){
    connect_to_stream();
    streamConnect = true;
  }
  //set_moisture_pixel();
  // Send new readings to database
  if ((millis() - sendDataPrevMillis > timerDelay || sendDataPrevMillis == 0)){
    sendDataPrevMillis = millis();
    timestamp = getTime();
    parentPath = databasePath + "/" + String(timestamp);
    set_wifi_pixels();
    pixels.show();
    //set_moisture_pixel();
    if (WiFi.status() == WL_CONNECTED && !first_connection){
      Serial.print("I am here!\n");
      timestamp = getTime();
      Serial.print ("time: ");
      Serial.println (timestamp);
      send_information_to_firebase();
      //check_settings();
      pixels.setPixelColor(0, pixels.Color(0, 50, 0));
      pixels.show();
    } else{
      if (WiFi.status() != WL_CONNECTED){
        pixels.setPixelColor(0, pixels.Color(50, 0, 0));
        pixels.show();
        //wifi_not_working();
        initWiFi();
        //delay(5000);
      }
      else{
        if(WiFi.status() == WL_CONNECTED && first_connection){
          //getting_server_for_the_first_time();
          pixels.setPixelColor(0, pixels.Color(0, 50, 0));
          pixels.show();
          timestamp = getTime();
          Serial.print ("time: ");
          Serial.println (timestamp);
          send_information_to_firebase();
          //check_settings();
        }
      }
    }
  }
  pixels.show();
  if (dataChanged_settings)
  {
    dataChanged_settings = false;
    Serial.printf("\n main loop detected data settings change \n");
    Serial.print("settings");
    check_settings();
  }
  if (dataChanged_tunning)
  {
    dataChanged_tunning = false;
    Serial.printf("\n main loop detected data tunning change \n");
    Firebase.RTDB.getInt(&fbdo, databaseGroundSetting + tuning, &tuning_on);
    if (tuning_on == 1){
      timerDelay_temp = timerDelay;
      timerDelay = 3000;
      Serial.print(timerDelay);
    }
    else{
        timerDelay = timerDelay_temp;
      }
    
    Serial.print("tunning");
    check_settings();
  }
}
