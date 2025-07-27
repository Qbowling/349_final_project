#define PIN_ENABLE_IN  4
#define PIN_DATA_IN    5

void setup() {
  // Set input pins
  pinMode(PIN_ENABLE_IN, INPUT);
  pinMode(PIN_DATA_IN, INPUT);

  // Start Serial Plotter
  Serial.begin(9600);
  Serial.println("Enable,Data"); // CSV headers for Serial Plotter
}

void loop() {
  // Signal start of transmission
  Serial.println("Waiting for new message...");
   while (digitalRead(PIN_ENABLE_IN) == LOW) {
        delay(5); // 5ms delay for loop while waiting for enable pin
      }
      Serial.println("Signal detected! Pin is HIGH.");
      Serial.println("--------NEW MESSAGE--------");
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

      delay(1000); 
    }
  }
}
