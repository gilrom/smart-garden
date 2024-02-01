#include <Arduino.h>

#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <Adafruit_BME280.h>
#include "time.h"

#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <DHT.h>

#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define OLED_RESET    -1  // Reset pin # (or -1 if sharing Arduino reset pin)

Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

#define DHT_PIN 25
#define MOISTURE_SENSOR_PIN 35
#define BUTTON_PIN 18

DHT dht11(DHT_PIN, DHT11);

// Provide the token generation process info.
#include "addons/TokenHelper.h"
// Provide the RTDB payload printing info and other helper functions.
#include "addons/RTDBHelper.h"


#define WIFI_SSID "Redmi Note 13 Pro+"
#define WIFI_PASSWORD "4wq9nyjdiscb5cu"

#define API_KEY "AIzaSyC9cPHW1Vie1sfCNnLh09TpMUO-65_zijo"

// Insert Authorized Email and Corresponding Password
#define USER_EMAIL "spektorroma@gmail.com"
#define USER_PASSWORD "qwerty123"

// Insert RTDB URLefine the RTDB URL
#define DATABASE_URL "https://database-for-iot-project-default-rtdb.europe-west1.firebasedatabase.app"

// Define Firebase objects
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

// Variable to save USER UID
String uid;

// Database main path (to be updated in setup with the user UID)
String databasePath;
// Database child nodes
String tempPath = "/temperature";
String humPath = "/humidity";
String moisPath = "/moistore";
String timePath = "/timestamp";

// Parent Node (to be updated in every loop)
String parentPath;

int timestamp = 0;
FirebaseJson json;

const char* ntpServer = "pool.ntp.org";

float temperature;
float humidity;
int moistureValue;

int first_connection = 0;

bool displayStatus = true;

unsigned long displayLastMillis = 0;
unsigned long displayTimeWaiting = 60000;

// Timer variables (send new readings every three minutes)
unsigned long sendDataPrevMillis = 0;
unsigned long timerDelay = 60000;

enum DisplayMode {
  TEMPERATURE,
  HUMIDITY,
  MOISTURE
};

DisplayMode currentMode = TEMPERATURE;

void switch_mode() {
  currentMode = static_cast<DisplayMode>((currentMode + 1) % 3);
}

void getting_server_for_the_first_time (){
  configTime(0, 0, ntpServer);

    // Assign the api key (required)
    config.api_key = API_KEY;

    // Assign the user sign in credentials
    auth.user.email = USER_EMAIL;
    auth.user.password = USER_PASSWORD;

    // Assign the RTDB URL (required)
    config.database_url = DATABASE_URL;

    Firebase.reconnectWiFi(true);
    fbdo.setResponseSize(4096);
    
    // Assign the callback function for the long running token generation task */
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
    first_connection = 1;
}

// Initialize WiFi
void initWiFi() {
  
  int attempts = 0;

  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to WiFi ..");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print('.');
    delay(1000);
    if (attempts < 10){
      attempts++;
    }
    else{
      Serial.print('\n');
      return;
    }
  }
  Serial.println(WiFi.localIP());
  Serial.println();
  if (first_connection == 0 && WiFi.status() == WL_CONNECTED){
    getting_server_for_the_first_time();
  }
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
}

void display_moisture() {
  moistureValue = analogRead(MOISTURE_SENSOR_PIN);
  display.setCursor((SCREEN_WIDTH - 12 * 4) / 2, 0);
  display.setTextSize(1);
  display.print("Moisture:");
  display.setCursor((SCREEN_WIDTH - 13 * 4) / 2, (SCREEN_HEIGHT - 16) / 2);
  display.setTextSize(2);
  display.print(moistureValue);
}

void wifi_not_working(){
  display.clearDisplay();
  display.setTextSize(2);
  display.setTextColor(SSD1306_WHITE);
  display.setCursor((SCREEN_WIDTH - 18 * 3) / 2, (SCREEN_HEIGHT - 16) / 2);
      
  display.print("NO WIFI!");

  display.display();
}

void send_information_to_firebase(){
  json.set(tempPath.c_str(), String(dht11.readTemperature()));
  json.set(humPath.c_str(), String(dht11.readHumidity()));
  json.set(moisPath.c_str(), String(analogRead(MOISTURE_SENSOR_PIN)));
  json.set(timePath, String(timestamp));
  Serial.printf("Set json... %s\n", Firebase.RTDB.setJSON(&fbdo, parentPath.c_str(), &json) ? "ok" : fbdo.errorReason().c_str());
}

void setup() {

  Serial.begin(115200);

  initWiFi();
  if (WiFi.status() == WL_CONNECTED && first_connection == 0){
    getting_server_for_the_first_time();
  }
  pinMode(BUTTON_PIN, INPUT_PULLUP);

  if(!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) { // Address 0x3C for 128x64
    Serial.println(F("SSD1306 allocation failed"));
    for(;;);
  }
  
  dht11.begin();

  display.display();
  delay(2000);
  display.clearDisplay();
}

void loop() {
  int buttonState = digitalRead(BUTTON_PIN);

  if (buttonState == LOW) {
    if (displayStatus){
      switch_mode();
    }
    displayStatus = true;
    displayLastMillis = millis();
    delay(100); // Optional debounce delay
  }
  if (displayStatus){
    display.clearDisplay();
    display.setTextSize(1);
    display.setTextColor(SSD1306_WHITE);

    switch (currentMode) {
      case TEMPERATURE:
        display_temperature();
        break;
      case HUMIDITY:
        display_humidity();
        break;
      case MOISTURE:
        display_moisture();
        break;
    }
    display.display();
    delay(100);
  }

  // Send new readings to database
  if ((millis() - sendDataPrevMillis > timerDelay || sendDataPrevMillis == 0)){
    sendDataPrevMillis = millis();

      //Get current timestamp

    parentPath= databasePath + "/" + String(timestamp);
    if (WiFi.status() == WL_CONNECTED && first_connection == 1){
      timestamp += 1;
      Serial.print ("time: ");
      Serial.println (timestamp);
      send_information_to_firebase();
    } else{
      if (WiFi.status() != WL_CONNECTED){
        wifi_not_working();
        initWiFi();
        delay(5000);
        displayStatus = true;
      }
    }
  }
  if ((millis() - displayLastMillis > displayTimeWaiting) && displayStatus){
    display.clearDisplay();
    displayStatus = false;
    display.display();
  }
}
