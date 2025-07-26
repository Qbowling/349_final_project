#define PIN_ENABLE_OUT 2
#define PIN_DATA_OUT   3
#define PIN_ENABLE_IN  4
#define PIN_DATA_IN    5

const byte testPattern[8] = {1, 0, 1, 1, 0, 1, 0, 1};  // B10110101

void setup() {
  // Set output pins
  pinMode(PIN_ENABLE_OUT, OUTPUT);
  pinMode(PIN_DATA_OUT, OUTPUT);

  // Set input pins
  pinMode(PIN_ENABLE_IN, INPUT);
  pinMode(PIN_DATA_IN, INPUT);

  // Start Serial Plotter
  Serial.begin(9600);
  Serial.println("Enable,Data"); // CSV headers for Serial Plotter
}

void loop() {
  // Signal start of transmission
  digitalWrite(PIN_ENABLE_OUT, HIGH);
  delay(100);  // Short delay to indicate ENABLE HIGH

  for (int i = 0; i < 8; i++) {
    // Set output bit
    digitalWrite(PIN_DATA_OUT, testPattern[i]);

    // Wait for 1 second while reading input
    unsigned long startTime = millis();
    while (millis() - startTime < 100) {
      int enableVal = digitalRead(PIN_ENABLE_IN);
      int dataVal   = digitalRead(PIN_DATA_IN);

      // Plot in Serial Plotter (CSV format with time axis)
      Serial.print(enableVal);
      Serial.print(",");
      Serial.println(dataVal);

      delay(1000); // sample rate: every 50ms
    }
  }

  // End transmission
  digitalWrite(PIN_ENABLE_OUT, LOW);
  digitalWrite(PIN_DATA_OUT, LOW);

  // Wait a bit before next test
  delay(5000);  // 5 second pause
  Serial.println("--------NEW MESSAGE--------");
}
