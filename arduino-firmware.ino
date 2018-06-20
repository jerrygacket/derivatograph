#include <HX711_ADC.h>
#include <SPI.h>    // include the SPI library:

//HX711 constructor (dout pin, sck pin)
HX711_ADC LoadCell(4, 5);
float tenz; // data from HX711

// for measures
long t,t1; // store time in milliseconds. t keep last measure time. t1 keep current milliseconds
// make measures one time in one second. if t1 > t + 1000 then must send data to pc
bool work = false; // send or dont send data to pc
long starttime=round(millis()/1000);

// for adc 7793
long temp1; //raw data from channel 1
long temp2; //raw data from channel 2
char csPin = 10; //where chipselect pin connected

void setup() {
  Serial.begin(115200);

  // HX711 setup
  LoadCell.begin();
  long stabilisingtime = 2000; // tare preciscion can be improved by adding a few seconds of stabilising time
  LoadCell.start(stabilisingtime);
  LoadCell.setCalFactor(670.0); // user set calibration factor (float)
  
  // spi setup
  SPI.begin();                           // wake up the SPI
  SPI.setDataMode(SPI_MODE3);            // datasheet p6-7
  SPI.setBitOrder(MSBFIRST);
  SPI.setClockDivider(SPI_CLOCK_DIV32);  // datasheet p6

  // adc setup
  adc_reset();
  
  Serial.print("Ready");
  Serial.print("\n");
}

void loop() {
  //LoadCell.update() should be called at least as often as HX711 sample rate; >10Hz@10SPS, >80Hz@80SPS
  //longer delay in scetch will reduce effective sample rate (be carefull with delay() in loop)
  LoadCell.update();
  if (work) {
    unsigned long statusByte;
      bool nodata;
      /***************************************************/
      adc_cr_write(0x15, 0x90); // amplifier 16, unipolar, channel 1
      //adc_mode_write(0x80,0x0A); //callibration "0". there is no effect, so dont do it
      adc_mode_write(0x20, 0x03); //freq 123 Гц, one measure
      nodata = true;
      while (nodata) {
        statusByte = adc_status_read();
        nodata = (statusByte >> 7);
      }
      temp1 = adc_read();
      /***************************************************/
      adc_cr_write(0x15, 0x91); // amplifier 16, unipolar, channel 2
      //adc_mode_write(0x80,0x0A); //callibration "0". there is no effect, so dont do it
      adc_mode_write(0x20, 0x03); //freq 123 Гц, one measure
      nodata = true;
      while (nodata) {
        statusByte = adc_status_read();
        nodata = (statusByte >> 7);
      }
      temp2 = adc_read();
      /***************************************************/
    t1 = millis();
    if (t1 > t + 1000) {
      tenz = LoadCell.getData();

      Serial.print(round(t1/1000)-starttime);
      Serial.print(";");
      Serial.print(tenz);
      Serial.print(";");
      Serial.print(temp1);
      Serial.print(";");
      Serial.print(temp2);
      Serial.print("\n");
      t = t1;
    }
  }

  //receive from serial terminal
  if (Serial.available() > 0) {
    char inByte = Serial.read();
    if (inByte == 't') LoadCell.tareNoDelay();
    else if (inByte == 'b') {starttime=round(millis()/1000);work=true;t = millis();}
    else if (inByte == 'e') work = false;
  }
}

void adc_reset() {
  unsigned char incomingByte = 0;
  digitalWrite(csPin, LOW);
  for (int i = 0; i < 4; i++) {        // send 0xFFFFFFFF
    incomingByte = SPI.transfer(0xFF);
  }
  digitalWrite(csPin, HIGH);
  delayMicroseconds(500);            // (datasheet --> p.23 ~p.19) wait 500us
}

unsigned char adc_status_read() {
  unsigned char incomingByte = 0;
  digitalWrite(csPin, LOW);
  incomingByte = SPI.transfer(0x40);
  incomingByte = SPI.transfer(0x00);
  digitalWrite(csPin, HIGH);
  return incomingByte;
}

// read from data register
unsigned long adc_read() {
  unsigned long registerValue = 0;
  unsigned char incomingByte = 0;
  digitalWrite(csPin, LOW);
  incomingByte = SPI.transfer(0x58); // read from data register
  for (int i = 0; i < 3; i++) {
    incomingByte = SPI.transfer(0x00);
    switch ( i ) {
      case 0:
        registerValue = incomingByte;
        break;
      case 1:
        registerValue <<= 8;
        registerValue |= incomingByte;
        break;
      case 2:
        registerValue <<= 8;
        registerValue |= incomingByte;
        break;
    }
  }
  digitalWrite(csPin, HIGH);
  return registerValue;
}

void adc_cr_write(char FirstByte, char SecondByte) {
  unsigned char incomingByte = 0;
  digitalWrite(csPin, LOW);
  incomingByte = SPI.transfer(0x10); // write in config register
  incomingByte = SPI.transfer(FirstByte); // data for write
  incomingByte = SPI.transfer(SecondByte); // data for write
  digitalWrite(csPin, HIGH);
}

void adc_mode_write(char FirstByte, char SecondByte) {
  unsigned char incomingByte = 0;
  digitalWrite(csPin, LOW);
  incomingByte = SPI.transfer(0x08); //write in mode register
  incomingByte = SPI.transfer(FirstByte); // data for write
  incomingByte = SPI.transfer(SecondByte); // data for write
  digitalWrite(csPin, HIGH);
}
