#include <Arduino.h>
#include <EEPROM.h>
#include <WiFi.h>
#include <Preferences.h>
#include <Firebase_ESP_Client.h>
#include <Adafruit_BME280.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <Adafruit_NeoPixel.h>
#include <Wire.h>
#include <DHT.h>
#include <climits>
#include <esp_task_wdt.h>
#include <NTPClient.h>

// Provide the token generation process info.
#include "addons/TokenHelper.h"
// Provide the RTDB payload printing info and other helper functions.
#include "addons/RTDBHelper.h"

#include "time.h"
#include "parameters.h"
#include "hardware.h"

//Temperture
DHT dht11(DHT_PIN, DHT11);

float s_temperature = 0;
float s_humidity = 0;
int s_moisture = 0;
int s_light = 0;

bool WIFI_status = false;

//WiFiUDP ntpUDP;
//NTPClient timeClient(ntpUDP);

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

//WiFi access point crediantinal
const char* ssid     = "ESP32-Access-Point";
const char* password = "";
bool first_wifi_connection = true;

// Set web server port number to 80
WiFiServer server(80);

// Variable to store the HTTP request
String header;

// Auxiliar variables to store the current output state
String output26State = "off";
String output27State = "off";

//String WIFI_SSID = "Admin";
//String WIFI_PASSWORD = "12345678";

// Database child nodes
String tempPath = "/temperature";
String humPath = "/humidity";
String moisPath = "/moisture";
String lightPath = "/light";

String newWifiSettings = "/new wifi settings";
String wifiName = "/wifi name";
String wifiPassword = "/wifi password";
String displayTimeOut = "/display time out";
String informationSendTime = "/send information to database";
String tuning = "/tuning";

// Parent Node (to be updated in every loop)
String parentPath;

int timestamp;
FirebaseJson json;
FirebaseJson json_set;

const char* ntpServer = "pool.ntp.org";
const long  gmtOffset_sec = 0;
const int   daylightOffset_sec = 3600;

bool first_connection = true;

// Timer variables (send new readings every ...)
unsigned long sendDataPrevMillis = 0;
unsigned long timerDelay = 100000;
unsigned long original_timerDelay = 10000;

int tunned_low_moisture = 10;
int tunned_high_moisture = 20;
int tunned_dry_moisture = 0;

int wifiSettingsChange = 0;

//WIFI
//String WIFI_SSID = "roi_sasson";
//String WIFI_PASSWORD = "12345678";

String WIFI_SSID = "Admin";
String WIFI_PASSWORD = "12345678";

//Device memory
float Target;

bool serverFirstTime = true;

time_t now;

unsigned long display_timeout = 10000;
int tuning_on = 0;

volatile bool dataChanged_settings = false;

const TickType_t xDelay1000 = 1000 / portTICK_PERIOD_MS;

void(* resetFunc) (void) = 0;//declare reset function at address 0

void EEPROMWriteString(int address, const String &data) 
{
	Serial.printf("EEPROMWriteString START\n");
	for (int i = 0; i < data.length(); i++) 
	{
		EEPROM.write(address + i, data[i]);
	}
	EEPROM.write(address + data.length(), '\0'); // Null terminator to indicate the end of the string
	EEPROM.commit();
	Serial.printf("EEPROMWriteString END\n");
}

String EEPROMReadString(int address) 
{
	Serial.printf("EEPROMReadString START\n");
	String data;
	char ch = EEPROM.read(address);
	for (int i = 0; ch != '\0' && i < EEPROM.length(); i++) 
	{
		data += ch;    // Append the character to the string
		ch = EEPROM.read(address + i + 1); // Read the next character
	}
	return data;
	Serial.printf("EEPROMReadString END\n");
}

void getting_server_for_the_first_time ()
{
	Serial.printf("getting_server_for_the_first_time START\n");
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
		vTaskDelay( xDelay1000 );
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
	Serial.printf("getting_server_for_the_first_time END\n");
}

bool WiFiConnect(String name, String password)
{
	Serial.printf("WiFiConnect START\n");
	Serial.printf("Name: %s, Password: %s\n", name, password);
	int attemps = 0;
	do 
	{
		WiFi.begin(name, password);
		vTaskDelay( xDelay1000 * 3 );
		attemps++;
	}
	while(WiFi.status() != WL_CONNECTED && attemps < 3);
	if (WiFi.status() == WL_CONNECTED)
	{
		EEPROM.begin(512); // Adjust size as needed
		EEPROMWriteString(EEPROM_WIFI_NAME_ADDRESS, name);
		EEPROMWriteString(EEPROM_WIFI_PASSWORD_ADDRESS, password);
		EEPROM.end();
		Serial.printf("WiFiConnect SUCCESS\n");
		return true;
	}
	else
	{
		Serial.printf("WiFiConnect FAILED\n");
		return false;
	}
}

// Initialize WiFi
void initWiFi() 
{
	Serial.printf("initWiFi START\n");
	bool connected = false;
	connected = WiFiConnect(WIFI_SSID, WIFI_PASSWORD);
	if(!connected)
	{
		String storedSSID = "";
		String storedPassword = "";
		EEPROM.get(0, Target);
		if (!isnan(Target))
		{
			EEPROM.begin(512); // Use the same size as in write
			storedSSID = EEPROMReadString(EEPROM_WIFI_NAME_ADDRESS);
			storedPassword = EEPROMReadString(EEPROM_WIFI_PASSWORD_ADDRESS);
			EEPROM.end();
			if (storedSSID.length() > 0 && storedPassword.length() > 0)
			{
				WiFiConnect(storedSSID.c_str(), storedPassword.c_str());
			}
		}
	}
	Serial.printf("initWiFi END\n");
}

void updateWifiStatus()
{
    if (WiFi.status() != WL_CONNECTED)
	{
    	WIFI_status = false;
    }
	else
	{
		WIFI_status = true;
	}
}

void streamCallback(FirebaseStream data)
{
	Serial.printf("streamCallback START\n");
	printResult(data);
	if (data.streamPath() == databaseSetting)
	{
		dataChanged_settings = true;
		FirebaseJson *jsonT = data.to<FirebaseJson *>();
        size_t len = jsonT->iteratorBegin();
        FirebaseJson::IteratorValue value;

        for (size_t i = 0; i < len; i++)
        {
            value = jsonT->valueAt(i);
			if(strcmp(value.key.c_str(), "display time out") == 0){
				display_timeout = atoi(value.value.c_str()) * 1000;
				Serial.printf("got display_timeout: %d\n", display_timeout);
			}
			else if(strcmp(value.key.c_str(), "send information to database") == 0){
				timerDelay = atoi(value.value.c_str()) * 1000;
				Serial.printf("got timerDelay: %d\n", timerDelay);
			}
			else if(strcmp(value.key.c_str(), "new wifi settings") == 0){
				wifiSettingsChange = atoi(value.value.c_str());
				Serial.printf("got wifiSettingsChange: %d\n", wifiSettingsChange);
			}
        }
        jsonT->iteratorEnd();
        jsonT->clear();
	}
	if(data.streamPath() == databaseGroundSetting)
	{
		// dataChanged_tunning = true;
		FirebaseJson *jsonT = data.to<FirebaseJson *>();
        size_t len = jsonT->iteratorBegin();
        FirebaseJson::IteratorValue value;

        for (size_t i = 0; i < len; i++)
        {
            value = jsonT->valueAt(i);
			if(strcmp(value.key.c_str(), "tuning") == 0){
				tuning_on = atoi(value.value.c_str());
				Serial.printf("got tuning_on: %d\n", tuning_on);
			}
			else if(strcmp(value.key.c_str(), "dry_value") == 0){
				tunned_dry_moisture = atoi(value.value.c_str());
				Serial.printf("got tunned_dry_moisture: %d\n", tunned_dry_moisture);
			}
			else if(strcmp(value.key.c_str(), "low_moist") == 0){
				tunned_low_moisture = atoi(value.value.c_str());
				Serial.printf("got tunned_low_moisture: %d\n", tunned_low_moisture);
			}
			else if(strcmp(value.key.c_str(), "high_moist") == 0){
				tunned_high_moisture = atoi(value.value.c_str());
				Serial.printf("got tunned_high_moisture: %d\n", tunned_high_moisture);
			}
        }
		if (tuning_on == 1 && timerDelay != TUNNING_DELAY)
		{
			original_timerDelay = timerDelay;
			timerDelay = TUNNING_DELAY;
			Serial.printf("changed timerDelay: %d\n", timerDelay);
		}
    	else
		{
			if (timerDelay == TUNNING_DELAY)
			{
				timerDelay = original_timerDelay;
				Serial.printf("changed timerDelay: %d\n", timerDelay);
			}
      	}
        jsonT->iteratorEnd();
        jsonT->clear();

	}
	Serial.printf("streamCallback END\n");
}

void streamTimeoutCallback(bool timeout)
{
	Serial.printf("streamTimeoutCallback START\n");
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
	Serial.printf("streamTimeoutCallback END\n");
}

void send_information_to_firebase()
{
	Serial.printf("send_information_to_firebase START\n");
	if (s_temperature != 0.0 || s_humidity != 0.0 || s_moisture != 0 || s_light != 0)
	{
		json.set(tempPath.c_str(), String(s_temperature));
		json.set(humPath.c_str(), String(s_humidity));
		json.set(moisPath.c_str(), String(s_moisture));
		json.set(lightPath.c_str(), String(s_light));

		if (Firebase.RTDB.setJSON(&fbdo, parentPath.c_str(), &json))
		{
			Serial.printf("Set json... ok\n");
		}
		else
		{
			Serial.printf("Set json... %s\n", fbdo.errorReason().c_str());
			if (strcmp(fbdo.errorReason().c_str(), "bad request") != 0)
			{
				if (Firebase.RTDB.setJSON(&fbdo, parentPath.c_str(), &json))
				{
					Serial.printf("Set json... ok\n");
				}
			}
			else if (strcmp(fbdo.errorReason().c_str(), "response payload read timed out") != 0 && strcmp(fbdo.errorReason().c_str(), "connection lost") != 0 && strcmp(fbdo.errorReason().c_str(), "not connected") != 0)
			{
				Serial.printf("Major error with FB maight need a reset\n");
				resetFunc(); //call reset 
			}
		}
	}
	
	Serial.printf("send_information_to_firebase END\n");
}

void fireBaseGetString(String str, String* value)
{
	if (Firebase.RTDB.getString(&fbdo, str, value))
	{
		return;
	}
	else
	{
		Serial.printf("ERROR reading data from FireBase\n");
	}
}

void connectNewWiFi()
{
	String new_wifi_name;
	String new_wifi_password;
	Serial.printf("connectNewWiFi START\n");
	fireBaseGetString(databaseSetting + wifiName, &new_wifi_name);
	fireBaseGetString(databaseSetting + wifiPassword, &new_wifi_password);

	int attempt = 0;
	while (!WiFiConnect(new_wifi_name, new_wifi_password) && attempt < 5)
	{
		attempt++;
	}
	if (WiFi.status() == WL_CONNECTED)
	{
		json_set.set(informationSendTime.c_str(), ((int)timerDelay/1000));
		json_set.set(displayTimeOut.c_str(), ((int)display_timeout/1000));
		json_set.set(newWifiSettings.c_str(), 0);
		json_set.set(wifiName.c_str(), new_wifi_name);
		json_set.set(wifiPassword.c_str(), new_wifi_password);
		
		for (int i = 0; i < 2; i++)
		{
			if (Firebase.RTDB.setJSON(&fbdo, databaseSetting.c_str(), &json_set))
			{
				Serial.printf("Set json... %s\n", "ok");
			}
			else
			{
				Serial.printf("Set json... %s\n", fbdo.errorReason().c_str());
				if (strcmp(fbdo.errorReason().c_str(), "bad request") != 0 && strcmp(fbdo.errorReason().c_str(), "response payload read timed out") != 0  && strcmp(fbdo.errorReason().c_str(), "connection lost") != 0  && strcmp(fbdo.errorReason().c_str(), "not connected") != 0)
				{
					Serial.printf("Major error with FB maight need a reset\n");
					resetFunc(); //call reset 
				}
			}
		}
	}
	else
	{
		Serial.printf("Error connecting to the new wifi\n");
	}
	wifiSettingsChange = 0;
	Serial.printf("connectNewWiFi END\n");
}

void connect_to_stream(){
	Serial.printf("connect_to_stream START\n");
	#if defined(ESP8266)
	stream_settings.setBSSLBufferSize(2048 /* Rx in bytes, 512 - 16384 */, 512 /* Tx in bytes, 512 - 16384 */);
	stream_tunning.setBSSLBufferSize(2048 /* Rx in bytes, 512 - 16384 */, 512 /* Tx in bytes, 512 - 16384 */);
	#endif

	if (!Firebase.RTDB.beginStream(&stream_settings, databaseSetting.c_str()))
	{
		Serial.printf("stream begin error, %s\n\n", stream_settings.errorReason().c_str());
	}
	if (!Firebase.RTDB.beginStream(&stream_tunning, databaseGroundSetting.c_str()))
	{
		Serial.printf("stream begin error, %s\n\n", stream_tunning.errorReason().c_str());
	}
	Firebase.RTDB.setStreamCallback(&stream_settings, streamCallback, streamTimeoutCallback);
	Firebase.RTDB.setStreamCallback(&stream_tunning, streamCallback, streamTimeoutCallback);
	Serial.printf("connect_to_stream END\n");
}

unsigned long getTime() 
{
	time_t now;
	time(&now);
	//Serial.println(&timeinfo, "%A, %B %d %Y %H:%M:%S");
	return now;
}

void setup() 
{
	Serial.begin(115200);
	esp_task_wdt_init(50, true);
	Serial.printf("setup START\n");
	
	initWiFi();
	if (WiFi.status() == WL_CONNECTED && first_connection)
	{
		getting_server_for_the_first_time();
		connect_to_stream();
		first_wifi_connection = false;
	}
	else if (WiFi.status() != WL_CONNECTED)
	{
		// Connect to Wi-Fi network with SSID and password
		Serial.print("Setting AP (Access Point)…");
		// Remove the password parameter, if you want the AP (Access Point) to be open
		WiFi.softAP(ssid, password);

		IPAddress IP = WiFi.softAPIP();
		Serial.print("AP IP address: ");
		Serial.println(IP);
		
		server.begin();
	}

	pinMode(BUTTON_PIN, INPUT_PULLUP);
	displayInit();
	//timeClient.begin();
	dht11.begin();

	//xTaskCreatePinnedToCore(HWLoop, "HWLoop", STACK_SIZE, nullptr, 1, nullptr, 0);
	xTaskCreate(HWLoop, "HWLoop", STACK_SIZE, nullptr, 1, nullptr);
	Serial.printf("setup END\n");
}

void WiFi_server()
{
	WiFiClient client = server.available();
	if (!client) {
		return;
	}

	Serial.println("New client");
	while (!client.available()) {
		vTaskDelay( xDelay1000/100 );
	}

	String request = client.readStringUntil('\r');
	Serial.println(request);
	client.flush();

	if (request.indexOf("/submit") != -1) {
		String wifiName = "";
		String wifiPass = "";
		if (request.indexOf("wifiName=") != -1) {
		wifiName = request.substring(request.indexOf("wifiName=") + 9);
		wifiName = wifiName.substring(0, wifiName.indexOf("&"));
		}
		if (request.indexOf("wifiPass=") != -1) {
		wifiPass = request.substring(request.indexOf("wifiPass=") + 9);
		wifiPass = wifiPass.substring(0, wifiPass.indexOf(" "));
		}
		Serial.print("Wi-Fi Name: ");
		Serial.println(wifiName);
		Serial.print("Wi-Fi Password: ");
		Serial.println(wifiPass);

		if (WiFiConnect(wifiName, wifiPass))
		{
			server.end();
			WiFi.softAPdisconnect (true);
			first_wifi_connection = false;
			return;
		}
	}

	client.println("HTTP/1.1 200 OK");
	client.println("Content-type:text/html");
	client.println();
	client.println("<html><head><title>ESP32 Wi-Fi Setup</title></head><body>");
	client.println("<h1>ESP32 Wi-Fi Setup</h1>");
	client.println("<form action='/submit' method='GET'>");
	client.println("Wi-Fi Name: <input type='text' name='wifiName'><br>");
	client.println("Wi-Fi Password: <input type='password' name='wifiPass'><br>");
	client.println("<input type='submit' value='Submit'>");
	client.println("</form>");
	client.println("</body></html>");

	Serial.println("Client disconnected");
}

void loop() 
{
	if (first_connection && WiFi.status() == WL_CONNECTED)
	{
		getting_server_for_the_first_time();
		connect_to_stream();
		server.end();
		first_wifi_connection = false;
	}
	
	updateWifiStatus();
	if (wifiSettingsChange == 1)
	{
		connectNewWiFi();
	}
	// Send new readings to database
	if ((millis() - sendDataPrevMillis > timerDelay || sendDataPrevMillis == 0) && !first_wifi_connection)
	{
		timestamp = getTime();
		Serial.print("Trying to send data to FB at time: ");
		Serial.println(timestamp);
		sendDataPrevMillis = millis();
		parentPath = databasePath + "/" + String(timestamp);
		if (WiFi.status() == WL_CONNECTED)
		{
			if (first_connection)
			{
				Serial.print("First time sending\n");
				getting_server_for_the_first_time();
			}
			Serial.print("WIFI connected, Sending data\n");
			send_information_to_firebase();
		} 
		else
		{
			Serial.print("No WIFI calling initWIFI\n");
			updateWifiStatus();
			initWiFi();
		}
	}
	if (first_wifi_connection && WiFi.status() != WL_CONNECTED)
	{
		WiFi_server();
	}
	vTaskDelay( xDelay1000 );
}
