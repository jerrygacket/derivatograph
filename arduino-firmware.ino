#include <HX711_ADC.h>
#include <SPI.h>    // include the SPI library:

//HX711 constructor (dout pin, sck pin)
HX711_ADC LoadCell(4, 5);
float tenz;

// для измерений
long t,t1;
bool work = false;
long starttime=round(millis()/1000);

// для АЦП
long temp1;
long temp2;
char csPin = 10; //Куда подключен пин чипселект

void setup() {
  Serial.begin(115200);

  // настройка тензодатчика
  LoadCell.begin();
  long stabilisingtime = 2000; // tare preciscion can be improved by adding a few seconds of stabilising time
  LoadCell.start(stabilisingtime);
  LoadCell.setCalFactor(670.0); // user set calibration factor (float)
  
  SPI.begin();                           // wake up the SPI
  SPI.setDataMode(SPI_MODE3);            // datasheet p6-7
  SPI.setBitOrder(MSBFIRST);
  SPI.setClockDivider(SPI_CLOCK_DIV32);  // datasheet p6

  // настройка ацп
  adc_reset();
  
  Serial.print("Ready");
  Serial.print("\n");
}

void loop() {
  //update() should be called at least as often as HX711 sample rate; >10Hz@10SPS, >80Hz@80SPS
  //longer delay in scetch will reduce effective sample rate (be carefull with delay() in loop)
  LoadCell.update();
  if (work) {
    unsigned long statusByte;
      bool nodata;
      /***************************************************/
      adc_cr_write(0x15, 0x90); // усиление 16, униполярный, канал 1
      //adc_mode_write(0x80,0x0A); //калибровка "0"
      adc_mode_write(0x20, 0x03); //частота измерения 123 Гц, одно преобразование
      nodata = true;
      while (nodata) {
        statusByte = adc_status_read();
        nodata = (statusByte >> 7);
      }
      temp1 = adc_read();
      /***************************************************/
      adc_cr_write(0x15, 0x91); // усиление 16, униполярный, канал 2
      //adc_mode_write(0x80,0x0A); //калибровка "0"
      adc_mode_write(0x20, 0x03); //частота измерения 123 Гц, одно преобразование
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

unsigned long adc_read() {
  unsigned long registerValue = 0;
  unsigned char incomingByte = 0;
  digitalWrite(csPin, LOW);
  incomingByte = SPI.transfer(0x58); // читаем из регистра данных
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
  incomingByte = SPI.transfer(0x10); // писать в конфиг регистр
  incomingByte = SPI.transfer(FirstByte); // что писать
  incomingByte = SPI.transfer(SecondByte); // что писать
  digitalWrite(csPin, HIGH);
}

void adc_mode_write(char FirstByte, char SecondByte) {
  unsigned char incomingByte = 0;
  digitalWrite(csPin, LOW);
  incomingByte = SPI.transfer(0x08); // писать в моде регистр
  incomingByte = SPI.transfer(FirstByte); // что писать
  incomingByte = SPI.transfer(SecondByte); // что писать
  digitalWrite(csPin, HIGH);
}
