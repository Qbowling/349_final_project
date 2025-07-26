#include <SoftwareSerial.h>

// Define SoftwareSerial pins: RX = D7, TX = D6
SoftwareSerial bluetooth(6, 7); // RX, TX

void setup() {
  // Start hardware serial for debugging
  Serial.begin(9600);
  while (!Serial);

  // Start software serial for Bluetooth
  bluetooth.begin(9600); // HC-05 default baud rate is 9600

  Serial.println("Bluetooth module ready. Waiting for connection...");
  bluetooth.println("Hello from Arduino!");
}

void loop() {
  // Read from Bluetooth and print to Serial Monitor
  if (bluetooth.available()) {
    char c = bluetooth.read();
    Serial.write(c);            // For debugging
    bluetooth.write(c);         // Echo back to Bluetooth
  }

  // Read from Serial Monitor and send to Bluetooth
  if (Serial.available()) {
    bluetooth.write(Serial.read());
  }
  bluetooth.write("Message every second\n");
  delay(1000);
}
