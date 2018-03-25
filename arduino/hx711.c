//-------------------------------------------------------------------------------------
// HX711_ADC.h
// Arduino master library for HX711 24-Bit Analog-to-Digital Converter for Weigh Scales
// Olav Kallhovd sept2017
// Tested with      : HX711 asian module on channel A and YZC-133 3kg load cell
// Tested with MCU  : Arduino Nano
//-------------------------------------------------------------------------------------
// This is an example sketch on how to use this library
// Settling time (number of samples) and data filtering can be adjusted in the HX711_ADC.h file
#include <HX711_ADC.h>

//HX711 constructor (dout pin, sck pin)
HX711_ADC LoadCell(4, 5);

long t;
long starttime;
bool work;

void setup() {
  Serial.begin(9600);
  Serial.println("Wait...");
  LoadCell.begin();
  long stabilisingtime = 2000; // tare preciscion can be improved by adding a few seconds of stabilising time
  LoadCell.start(stabilisingtime);
  LoadCell.setCalFactor(670.0); // user set calibration factor (float)
  Serial.println("Startup + tare is complete");
  starttime=round(millis()/1000);
  work=false;
}

void loop() {
  //update() should be called at least as often as HX711 sample rate; >10Hz@10SPS, >80Hz@80SPS
  //longer delay in scetch will reduce effective sample rate (be carefull with delay() in loop)
  LoadCell.update();

  //get smoothed value from data set + current calibration factor
  if (work) {
    if (millis() > t + 1000) {
      float i = LoadCell.getData();
      float v = LoadCell.getCalFactor();
      Serial.print(round(millis()/1000)-starttime);
      Serial.print(";");
      Serial.print(i);
      Serial.print(";");
      Serial.print(v);
      Serial.print("\n");
      t = millis();
    }
  }

  //receive from serial terminal
  if (Serial.available() > 0) {
    float i;
    char inByte = Serial.read();
    if (inByte == 't') LoadCell.tareNoDelay();
    else if (inByte == 'b') {starttime=round(millis()/1000);work=true;}
    else if (inByte == 'e') {work=false;}
    else if (inByte == 'l') i = -1.0;
    else if (inByte == 'L') i = -10.0;
    else if (inByte == 'h') i = 1.0;
    else if (inByte == 'H') i = 10.0;
    if (i != 't') {
      float v = LoadCell.getCalFactor() + i;
      LoadCell.setCalFactor(v);
    }
  }

  //check if last tare operation is complete
  if (LoadCell.getTareStatus() == true) {
    Serial.println("Tare complete");
  }

}
