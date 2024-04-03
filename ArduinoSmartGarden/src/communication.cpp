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
#include "parameters.h"

String informationSendTime = "/send information to database";
String newWifiSettings = "/new wifi settings";
String wifiTroubleCheck = "/wifi wrong name or password";
String wifiName = "/wifi name";
String wifiPassword = "/wifi password";

float temperature_value;
float humidity_value;
int moisture_value; 
float moisture_percent;
int light_value;
DHT dht11(DHT_PIN, DHT11);
int light_percent;
bool report_wifi_to_pixel;
int tuning_on;
float Target;

const long  gmtOffset_sec = 0;
const int   daylightOffset_sec = 3600;


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

WebServer server(80);

const char* ntpServer = "pool.ntp.org";

bool first_connection = true;

String newWifiName;
String newWifiPassword;
String WIFI_SSID_temp = "";
String WIFI_PASSWORD_temp = "";
bool wifiTrouble = false;

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
	while ((auth.token.uid) == "") 
	{
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

String EEPROMReadString(int address) {
	String data;
	char ch = EEPROM.read(address);
	for (int i = 0; ch != '\0' && i < EEPROM.length(); i++) {
		data += ch;    // Append the character to the string
		ch = EEPROM.read(address + i + 1); // Read the next character
	}
	return data;
}

// Initialize WiFi
void initWiFi() 
{
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
  
	if (!isnan(Target) && WiFi.status() != WL_CONNECTED)
	{
		EEPROM.begin(512); // Use the same size as in write
		storedSSID = EEPROMReadString(EEPROM_WIFI_NAME_ADDRESS);
		storedPassword = EEPROMReadString(EEPROM_WIFI_PASSWORD_ADDRESS);
		EEPROM.end();

		Serial.print(storedSSID);
		Serial.print('\n');
		Serial.print(storedPassword);
		Serial.print('\n');

		if (storedSSID.length() > 0 && storedPassword.length() > 0) 
		{
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
	if (WiFi.status() == WL_CONNECTED)
	{
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
		if (first_connection && WiFi.status() == WL_CONNECTED)
		{
			getting_server_for_the_first_time();
		}
		//EEPROM.end();
}

void send_information_to_firebase(){
	json.set(tempPath.c_str(), String(dht11.readTemperature()));
	json.set(humPath.c_str(), String(dht11.readHumidity()));
	
	moisture_value = analogRead(MOISTURE_SENSOR_PIN);
	Serial.print(moisture_value);
	Serial.print("\n");
	moisture_percent = map(moisture_value, 4095, 0, 0, 100);

	light_value = analogRead(LIGHT_SENSOR_PIN);
	light_percent = map(light_value, DarkValue, LightValue, 0, 100);

	json.set(moisPath.c_str(), String(moisture_percent));
	json.set(lightPath.c_str(), String(light_percent));

	if (Firebase.RTDB.setJSON(&fbdo, parentPath.c_str(), &json))
	{
		Serial.printf("Set json... %s\n", "ok");
	}
	else
	{
		Serial.printf("Set json... %s\n", fbdo.errorReason().c_str());
		if (strcmp(fbdo.errorReason().c_str(), "bad request") != 0)
		{
			resetFunc(); //call reset 
		}
	}
}

bool firstTimeCheckSettings = true;
void check_settings(){
	Firebase.RTDB.getInt(&fbdo, databaseSetting + newSettings, &settingsChange);
	Firebase.RTDB.getInt(&fbdo, databaseSetting + newWifiSettings, &wifiSettingsChange);
	Firebase.RTDB.getInt(&fbdo, databaseGroundSetting + newGroundSettings, &groundSettingsChange);
	Firebase.RTDB.getInt(&fbdo, databaseGroundSetting + tuning, &tuning_on);
	if (settingsChange == 1 || firstTimeCheckSettings)
	{
		Firebase.RTDB.getInt(&fbdo, databaseSetting + displayTimeOut, &newdisplayTimeWaiting);
		Firebase.RTDB.getInt(&fbdo, databaseSetting + informationSendTime, &newtimerDelay);
		display_timeout = newdisplayTimeWaiting;
		timerDelay = newtimerDelay;
		timerDelay_temp = newtimerDelay;
	}
	if (tuning_on == 1 && settingsChange == 0 && !firstTimeCheckSettings && oneTime)
	{
		timerDelay_temp = timerDelay;
		timerDelay = 3000;
		oneTime = false;
	}
	else
	{
		if (tuning_on == 0 && settingsChange == 0 && !firstTimeCheckSettings && !oneTime)
		{
			timerDelay = timerDelay_temp;
			oneTime = true;
		}
	}
	if (wifiSettingsChange == 1)
	{
		Firebase.RTDB.getString(&fbdo, databaseSetting + wifiName, &newWifiName);
		Firebase.RTDB.getString(&fbdo, databaseSetting + wifiPassword, &newWifiPassword);
		WIFI_SSID_temp = newWifiName;
		WIFI_PASSWORD_temp = newWifiPassword;
	}
	if (groundSettingsChange == 1 || firstTimeCheckSettings)
	{
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
	
		if (Firebase.RTDB.setJSON(&fbdo, databaseGroundSetting.c_str(), &json_ground))
		{
			Serial.printf("Set json... %s\n", "ok");
		}
		else
		{
			Serial.printf("Set json... %s\n", fbdo.errorReason().c_str());
			if (strcmp(fbdo.errorReason().c_str(), "bad request") != 0)
			{
				resetFunc(); //call reset 
			}
		}
	}
	if (settingsChange == 1 || wifiSettingsChange == 1 || firstTimeCheckSettings || wifiTrouble)
	{
		json_set.set(displayTimeOut.c_str(), int(display_timeout));
		json_set.set(informationSendTime.c_str(), int(timerDelay));
		json_set.set(newSettings.c_str(), 0);
		json_set.set(newWifiSettings.c_str(), 0);
		json_set.set(wifiTroubleCheck.c_str(), wifiTrouble);
		json_set.set(wifiName.c_str(), WIFI_SSID_temp);
		json_set.set(wifiPassword.c_str(), WIFI_PASSWORD_temp);
		//Serial.printf("Set json... %s\n", Firebase.RTDB.setJSON(&fbdo, databaseSetting.c_str(), &json_set) ? "ok" : fbdo.errorReason().c_str());
		if (Firebase.RTDB.setJSON(&fbdo, databaseSetting.c_str(), &json_set))
		{
			Serial.printf("Set json... %s\n", "ok");
		}
		else
		{
			Serial.printf("Set json... %s\n", fbdo.errorReason().c_str());
			//resetFunc(); //call reset 
		}
	}
	if (wifiSettingsChange == 1)
	{
		WiFi.begin(WIFI_SSID_temp, WIFI_PASSWORD_temp);
		int attempt = 0;
		while (WiFi.status() != WL_CONNECTED) 
		{
			Serial.print('.');
			
			delay(1000);
			if (attempt < 10){
			attempt++;
		}
		else
		{
			Serial.print('\n');
			return;
		}
	}
		if (WiFi.status() != WL_CONNECTED)
		{
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
	{
		dataChanged_settings = true;
	}
	else
	{
		dataChanged_tunning = true;
	}
}

void streamTimeoutCallback(bool timeout)
{
	if (timeout)
	{
		Serial.println("stream timed out, resuming...\n");

	}
	if (!stream_settings.httpConnected())
	{
		Serial.printf("error code: %d, reason: %s\n\n", stream_settings.httpCode(), stream_settings.errorReason().c_str());
	}
	if (!stream_tunning.httpConnected())
	{
		Serial.printf("error code: %d, reason: %s\n\n", stream_tunning.httpCode(), stream_tunning.errorReason().c_str());
	}
}

unsigned long getTime() 
{
	time_t now;
	
	time(&now);
	//Serial.println(&timeinfo, "%A, %B %d %Y %H:%M:%S");
	return now;
}


void communicationLoop(void* param)
{
	int timestamp;
	// Send new readings to database
	if ((millis() - sendDataPrevMillis > timerDelay || sendDataPrevMillis == 0))
	{
		sendDataPrevMillis = millis();
		timestamp = getTime();
		parentPath = databasePath + "/" + String(timestamp);
		if (WiFi.status() == WL_CONNECTED && !first_connection)
		{
			timestamp = getTime();
			Serial.print ("time: ");
			Serial.println (timestamp);
			send_information_to_firebase();
			check_settings();
			pixels.setPixelColor(0, pixels.Color(0, 150, 0));
			pixels.show();
		} 
		else
		{
			if (WiFi.status() != WL_CONNECTED)
			{
				pixels.setPixelColor(0, pixels.Color(255, 0, 0));
				pixels.show();
				//wifi_not_working();
				initWiFi();
				//delay(5000);
			}
			else
			{
				if(WiFi.status() == WL_CONNECTED && first_connection)
				{
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
	if (dataChanged_settings)
	{
		dataChanged_settings = false;
		Serial.printf("\n main loop detected data settings change \n");
		check_settings();
	}
	if (dataChanged_tunning)
	{
		dataChanged_tunning = false;
		Serial.printf("\n main loop detected data tunning change \n");
		check_settings();
  	}
}