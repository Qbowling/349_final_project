#define PIN_ENABLE_IN  4
#define PIN_DATA_IN    5

#include <SoftwareSerial.h>
#include <string.h>

// Define SoftwareSerial pins: RX = D7, TX = D6
SoftwareSerial bluetooth(6, 7); // RX, TX

void setup() {
  // Set input pins
  pinMode(PIN_ENABLE_IN, INPUT);
  pinMode(PIN_DATA_IN, INPUT);

  // Start Serial Plotter
  Serial.begin(9600);
  while (!Serial);

  // Start software serial for Bluetooth
  bluetooth.begin(9600); // HC-05 default baud rate is 9600

  Serial.println("Bluetooth module ready. Waiting for connection...");
  bluetooth.println("Hello from Arduino!");
}

void loop() {
  int packetToSend[] = {0, 0, 0, 0, 0, 0, 0, 0};
  int reverseCounter = 7;
  // Signal start of transmission
  Serial.println("Waiting for new message...");
  while (digitalRead(PIN_ENABLE_IN) == LOW) {
      delay(5); // 5ms delay for loop while waiting for enable pin
  }
  Serial.println("Signal detected! Pin is HIGH.");
  Serial.println("--------NEW MESSAGE--------");
  Serial.println("Enable,Data"); // CSV headers for Serial Plotter
  delay(600);  // Short delay to read after enable pin

  for (int i = 0; i < 8; i++) {
    // Wait for 1 second while reading input
    unsigned long startTime = millis();
    while (millis() - startTime < 100) {
      int enableVal = digitalRead(PIN_ENABLE_IN);
      int dataVal   = digitalRead(PIN_DATA_IN);
      
      // Plot in Serial Plotter (CSV format with time axis)
      Serial.print(enableVal);
      Serial.print(",");
      Serial.println(dataVal);

      packetToSend[reverseCounter] = dataVal;
      reverseCounter--;
      delay(1000); 
    }
  }

  uint8_t resultByte = convertPacketToByte(packetToSend, bluetooth);
}

uint8_t convertPacketToByte(const int packet[8], SoftwareSerial &bluetooth) {
  uint8_t result = 0;

  // Combine bits (MSB at index 0, LSB at index 7)
  for (int i = 0; i < 8; i++) {
    result |= (packet[i] & 0x01) << (7 - i);
  }

  // ---------- Print Binary ----------
  Serial.print("Binary: 0b");
  bluetooth.print("Binary: 0b");
  for (int i = 7; i >= 0; i--) {
    int bit = (result >> i) & 0x01;
    Serial.print(bit);
    bluetooth.print(bit);
  }
  Serial.println();
  bluetooth.println();

  // ---------- Print Hex ----------
  Serial.print("Hex: 0x");
  bluetooth.print("Hex: 0x");
  if (result < 0x10) {
    Serial.print("0");
    bluetooth.print("0");
  }
  Serial.println(result, HEX);
  bluetooth.println(result, HEX);

  // ---------- Print Decimal ----------
  Serial.print("Int: ");
  bluetooth.print("Int: ");
  Serial.println(result);
  bluetooth.println(result);

  return result;
}


