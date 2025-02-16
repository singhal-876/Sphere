//SPHERE BAND IDE CODE
#include <Arduino.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <Wire.h>
#include "MAX30105.h"
#include "heartRate.h"

#define DEBUG true

// Pin Configurations for Seeed Studio XIAO ESP32C3
const int A9G_PON = D10;
const int A9G_LOWP = D2;
const int SOS_Button = D3;
const int BLE_Button = D4;

// Variables
String inputString = "";
String fromGSM = ""; 
bool CALL_END = true;
String response = "";
String res = "";
int c = 0;
String msg;
String custom_message;
bool systemOn = true;
bool bleActive = false;
bool deviceConnected = false;
String SOS_NUM = "+917906605631";

const int SOS_Time = 5;

// MAX30102 variables for heart rate
MAX30105 particleSensor;
const byte RATE_SIZE = 4;
byte rates[RATE_SIZE];
byte rateSpot = 0;
long lastBeat = 0;
float beatsPerMinute;
int beatAvg;

// Adaptive thresholding variables
const int SAMPLE_SIZE = 100;
long irSamples[SAMPLE_SIZE];
int sampleIndex = 0;

#define SERVICE_UUID "12345678-1234-1234-1234-123456789012"
#define CHARACTERISTIC_UUID "abcd1234-ab12-cd34-ef56-abcdef123456"
#define HEARTRATE_CHARACTERISTIC_UUID "2a37"

BLEServer* pServer = NULL;
BLECharacteristic* pCharacteristic = NULL;
BLECharacteristic* pHeartRateCharacteristic = NULL;

// BLE Server Callbacks
class MyServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) override {
    deviceConnected = true;
    Serial.println("BLE Device Connected");
  }

  void onDisconnect(BLEServer* pServer) override {
    deviceConnected = false;
    Serial.println("BLE Device Disconnected");
    pServer->getAdvertising()->start();
  }
};

void processBLEData(String bleData);

// BLE Characteristic Callbacks
class MyCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* pCharacteristic) override {
    std::string value = pCharacteristic->getValue();
    if (value.length() > 0) {
      String bleData = String(value.c_str());
      processBLEData(bleData);
    }
  }
};

// Function Declarations
void initializeGSM();
void A9G_Ready_msg();
void toggleBLE();
void processGSMMessage();
void handleSOSButtonPress();
String sendData(String command, const int timeout, boolean debug);
void configureGSM();
void Get_gmap_link(bool makeCall);
String readGSMData();
void processLocationData(String location);
void checkBatteryStatus();
void autoAnswerCall();
void endCall();
void Send_SMS(String message);
void setupMAX30102();
void readMAX30102();
long getAdaptiveThreshold();
void updateIRSamples(long newValue);

void setup() {
  Serial.begin(115200);
  Serial1.begin(115200, SERIAL_8N1, D0, D1); // Use D0 and D1 for A9G communication

  pinMode(A9G_PON, OUTPUT);
  pinMode(A9G_LOWP, OUTPUT);
  pinMode(SOS_Button, INPUT_PULLUP);
  pinMode(BLE_Button, INPUT_PULLUP);

  // Power on A9G and initialize GSM
  digitalWrite(A9G_LOWP, HIGH);
  digitalWrite(A9G_PON, HIGH);
  delay(1000);
  digitalWrite(A9G_PON, LOW);
  delay(10000); // Wait for A9G to initialize
  digitalWrite(A9G_LOWP, LOW); // Exit sleep mode

  initializeGSM(); // Initialize the GSM module
  A9G_Ready_msg(); // Notify that A9G is ready
  digitalWrite(A9G_LOWP, HIGH); // Return to sleep mode

  // Initialize BLE
  BLEDevice::init("SafetyBand");
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  BLEService* pService = pServer->createService(SERVICE_UUID);

  pCharacteristic = pService->createCharacteristic(
    CHARACTERISTIC_UUID,
    BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_WRITE
  );
  pCharacteristic->addDescriptor(new BLE2902());
  pCharacteristic->setCallbacks(new MyCallbacks());

  pHeartRateCharacteristic = pService->createCharacteristic(
    HEARTRATE_CHARACTERISTIC_UUID,
    BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY
  );
  pHeartRateCharacteristic->addDescriptor(new BLE2902());

  pService->start();
  pServer->getAdvertising()->start();
  Serial.println("Waiting for BLE client to connect...");

  // Initialize MAX30102 sensor
  setupMAX30102();

  // Initialize IR samples with default values
  for (int i = 0; i < SAMPLE_SIZE; i++) {
    irSamples[i] = 7000; // Starting threshold
  }
}

void loop() {
  // Handle BLE Button
  if (digitalRead(BLE_Button) == LOW) {
    toggleBLE();
    delay(500);
  }

  // Handle GSM Communication
  if (systemOn && Serial1.available()) {
    char inChar = Serial1.read();
    if (inChar == '\n') {
      processGSMMessage();
    } else {
      fromGSM += inChar;
    }
    delay(20);
  }

  // Handle SOS Button
  if (systemOn && digitalRead(SOS_Button) == LOW && CALL_END) {
    handleSOSButtonPress();
  }

  // Handle Heart Rate Monitoring when BLE is connected
  if (deviceConnected) {
    readMAX30102();
  }
}

void setupMAX30102() {
  if (!particleSensor.begin(Wire, I2C_SPEED_FAST)) {
    Serial.println("MAX30105 was not found. Please check wiring/power.");
    while (1);
  }

  particleSensor.setup(); // Set up the sensor
  particleSensor.setPulseAmplitudeRed(0x0A);
  particleSensor.setPulseAmplitudeGreen(0);
}

void readMAX30102() {
  long irValue = particleSensor.getIR();
  updateIRSamples(irValue);
  long threshold = getAdaptiveThreshold();

  if (irValue > threshold) {
    if (checkForBeat(irValue) == true) {
      long delta = millis() - lastBeat;
      lastBeat = millis();
      beatsPerMinute = 60 / (delta / 1000.0);

      if (beatsPerMinute < 255 && beatsPerMinute > 20) {
        rates[rateSpot++] = (byte)beatsPerMinute;
        rateSpot %= RATE_SIZE;

        beatAvg = 0;
        for (byte x = 0; x < RATE_SIZE; x++) {
          beatAvg += rates[x];
        }
        beatAvg /= RATE_SIZE;

        // Notify BLE client
        String heartRateData = "BPM: " + String(beatAvg);
        pHeartRateCharacteristic->setValue(heartRateData.c_str());
        pHeartRateCharacteristic->notify();
      }
    }
  } else {
    static bool lastWristState = true;
    if (lastWristState) {
      pHeartRateCharacteristic->setValue("No wrist detected");
      pHeartRateCharacteristic->notify();
      lastWristState = false;
    }
    beatsPerMinute = 0;
    beatAvg = 0;
  }

  // Debug output
  Serial.print("IR=");
  Serial.print(irValue);
  Serial.print(", Threshold=");
  Serial.print(threshold);
  Serial.print(", BPM=");
  Serial.print(beatsPerMinute);
  Serial.print(", Avg BPM=");
  Serial.println(beatAvg);
}

long getAdaptiveThreshold() {
  long sum = 0;
  for (int i = 0; i < SAMPLE_SIZE; i++) {
    sum += irSamples[i];
  }
  long average = sum / SAMPLE_SIZE;
  return average * 0.8; // Set threshold to 70% of the average
}

void updateIRSamples(long newValue) {
  irSamples[sampleIndex] = newValue;
  sampleIndex = (sampleIndex + 1) % SAMPLE_SIZE;
}

void initializeGSM() {
  msg = sendData("AT", 1000, DEBUG);
  while (msg.indexOf("OK") == -1) {
    msg = sendData("AT", 1000, DEBUG);
    Serial.println("Trying to connect to A9G");
  }
  configureGSM();
}

void configureGSM() {
  sendData("AT+GPS=1", 2000, DEBUG);
  sendData("AT+GPSLP=2", 2000, DEBUG);
  sendData("AT+SLEEP=1", 2000, DEBUG);
  sendData("AT+CMGF=1", 2000, DEBUG);
  sendData("AT+CSMP=17,167,0,0", 2000, DEBUG);
  sendData("AT+CPMS=\"SM\",\"ME\",\"SM\"", 2000, DEBUG);
  sendData("AT+SNFS=2", 2000, DEBUG);
  sendData("AT+CLVL=8", 2000, DEBUG);
}
void processGSMMessage() {
  if (fromGSM == "SEND LOCATION\r" || fromGSM == "send location\r") {
    Get_gmap_link(false);
    digitalWrite(A9G_LOWP, HIGH);
  } else if (fromGSM == "BATTERY?\r") {
    digitalWrite(A9G_LOWP, LOW);
    checkBatteryStatus();
  } else if (fromGSM == "RING\r") {
    autoAnswerCall();
  } else if (fromGSM == "NO CARRIER\r") {
    endCall();
  }
  Serial.println(fromGSM);
  fromGSM = "";
}

void handleSOSButtonPress() {
  Serial.print("SOS Triggered, calling in..");
  for (c = 0; c < SOS_Time; c++) {
    Serial.println((SOS_Time - c));
    delay(1000);
    if (digitalRead(SOS_Button) == HIGH) break;
  }

  if (c == SOS_Time) {
    Get_gmap_link(true);  // Trigger SOS with location
  }
}

void processBLEData(String bleData) {
  if (bleData == "SOS") {
    Get_gmap_link(true);  // Trigger SOS via BLE
  } else if (bleData.startsWith("NUMBER:")) {
    SOS_NUM = bleData.substring(7);  // Update SOS number via BLE
    Serial.println("Updated SOS number: " + SOS_NUM);
  }
}

void Get_gmap_link(bool makeCall) {
  digitalWrite(A9G_LOWP, LOW);
  delay(1000);
  Serial1.println("AT+LOCATION=2");
  String location = readGSMData();
  processLocationData(location);

  if (makeCall) {
    Serial1.println("ATD" + SOS_NUM);  // Make the call
    CALL_END = false;
  }
}

// void Get_gmap_link(bool makeCall) {
//     digitalWrite(A9G_LOWP, LOW);
//     delay(1000);
//     Serial1.println("AT+LOCATION=2"); // Attempt to fetch GPS location first
//     String location = readGSMData();

//     if (location.indexOf("GPS NOT") != -1) { 
//         // Fallback to LBS if GPS is not available
//         Serial1.println("AT+LOCATION=1"); // Request location from network
//         location = readGSMData();
//     }

//     processLocationData(location);

//     if (makeCall) {
//         Serial1.println("ATD" + SOS_NUM);  // Make the call
//         CALL_END = false;
//     }
// }


String readGSMData() {
  String temp = "";
  long int time = millis();
  while ((time + 1000) > millis()) {
    while (Serial1.available()) {
      char c = Serial1.read();
      temp += c;
    }
  }
  return temp;
}

void processLocationData(String location) {
  res = location.substring(17, 38);
  response = res;

  if (response.indexOf("GPS NOT") != -1) {
    Serial.println("No Location data");
    custom_message = "Unable to fetch location. Please try again";
    Send_SMS(custom_message);
  } else {
    int i = 0;
    while (response[i] != ',') i++;
    String lat = res.substring(2, i);
    String longi = res.substring(i + 1);
    String Gmaps_link = "Help: http://maps.google.com/maps?q=" + lat + "+" + longi;

    custom_message = Gmaps_link;
    Send_SMS(custom_message);
  }

  response = "";
  res = "";
}

void checkBatteryStatus() {
  Serial.println("Checking battery status...");
  msg = sendData("AT+CBC?", 2000, DEBUG);
  while (msg.indexOf("OK") == -1) {
    msg = sendData("AT+CBC?", 1000, DEBUG);
    Serial.println("Trying to get battery status");
  }
  msg = msg.substring(19, 24);
  Send_SMS("Battery Status: " + msg);
}

void autoAnswerCall() {
  Serial1.println("ATA");
  Serial.println("Auto-answering the call...");
}

void endCall() {
  Serial1.println("ATH");
  Serial.println("Ending the call...");
  CALL_END = true;
}

void Send_SMS(String message) {
  Serial1.println("AT+CMGF=1");  // Set SMS to text mode
  delay(1000);
  Serial1.println("AT+CMGS=\"" + SOS_NUM + "\"\r");  // Send SMS to the SOS number
  delay(1000);
  Serial1.println(message);
  delay(1000);
  Serial1.println((char)26);  // Ctrl+Z to send SMS
  delay(1000);
  Serial1.println("AT+CMGD=1,4");  // Delete message from memory
  delay(3000);
}

void A9G_Ready_msg() {
  custom_message = "SPHERE READY!!";
  Send_SMS(custom_message);  // Notify that the GSM module is ready
}

String sendData(String command, const int timeout, boolean debug) {
  String temp = "";
  Serial1.println(command);
  long int time = millis();
  while ((time + timeout) > millis()) {
    while (Serial1.available()) {
      char c = Serial1.read();
      temp += c;
    }
  }
  if (debug) {
    Serial.print(temp);
  }
  return temp;
}

void toggleBLE() {
  if (bleActive) {
    pServer->getAdvertising()->stop();  // Stop BLE advertising
    bleActive = false;
    Serial.println("BLE turned OFF");
  } else {
    pServer->getAdvertising()->start();  // Start BLE advertising
    bleActive = true;
    Serial.println("BLE turned ON");
  }
}