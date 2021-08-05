#include <HX711_ADC.h>


//#include "HX711.h"

//LOS PINES SON ESTOS:
//celula de carga
const int DOUT = A1;
const int CLK = A0;
//encoder
const int PinCLK=3;                   // Used for generating interrupts using CLK signal
const int PinDT=2;                    // Used for reading DT signal



//A PARTIR DE AQUI ES EL FUNCIONAMIENTO, NO TOCAR.
#define SAMPLE_RATE 250 //sample every SAMPLE_RATE ms

HX711_ADC cell(DOUT,CLK);

volatile boolean TurnDetected;
volatile boolean up;
static long virtualPosition=0;    // without STATIC it does not count correctly!!!

unsigned long previousTime = 0.0;
unsigned long t = 0;

//Declaracion de funcion de tara
void set_zero(){

  bool newData = 0;
  int espera = 0, count = 0;
  unsigned long val[30];
  unsigned long suma = 0;
  unsigned long media = 0;
  
  cell.setTareOffset(0);
  cell.setCalFactor(1);

  while(count < 50){
    if (cell.update()) newData = true;
    if (newData) {
      val[count] = cell.getData();
      
      newData = 0;
      
      if(count>=20){
        suma+=val[count];
        Serial.print("valor");
      Serial.print(count);
      Serial.print(": ");
      Serial.print(val[count]);
      Serial.println();
      }

      count++;
      
      delay(500);
    }
  }
/*
  for(int k=20; k < 50; k++){
    suma+=val[k];
  }
*/
  media = suma/30;

  cell.setTareOffset(media);
  Serial.print("media: ");
  Serial.print(media);
  Serial.println();
  cell.setCalFactor(-512.89);
}

void isr ()  {                    // Interrupt service routine 
 if (digitalRead(PinCLK))
   up = digitalRead(PinDT);
 else
   up = !digitalRead(PinDT);
 //TurnDetected = true;
 if (up)
     virtualPosition++;
   else
     virtualPosition--;
}


void setup ()  {
   Serial.begin (115200);
 pinMode(PinCLK,INPUT);
 pinMode(PinDT,INPUT);  
 // interrupt 0 is always connected to pin 2 on Arduino UNO
 // RISING 1 interrupt per pulse
    //attachInterrupt (0,isr,RISING); 
 // FALLING 1 interrupt per pulse
    //attachInterrupt (0,isr,FALLING); 
 // CHANGE 2 interrupt per pulse (more accurate)
    attachInterrupt (0,isr,CHANGE); 

 /****************************funciones de HX711.h***********************
 // set the SCALE value; this value is used to convert the raw data to "human readable" data (measure units)
 //void set_scale(float scale = 1.f);
 cell.set_scale(1171.6);

 // set the OFFSET value for tare weight; times = how many times to read the tare value
 //void tare(byte times = 10);
 cell.tare(5000);
 ***********************************************************************/
 
 /****************************funciones de HX711_ADC.h***********************/
 cell.begin();

  //set new tare offset (raw data value input without the scale "calFactor")
 //cell.setTareOffset(0);
 //cell.setTareOffset(7000050);
 
 //set new calibration factor, raw data is divided by this value to convert to readable data modifica "calFactorRecip"
 //cell.setCalFactor(-512.89);
 //cell.setCalFactor(1);


 /***************************************************************************/ 
  
 
set_zero();
 /*
 Serial.println("Ready...");
 Serial.println("Sending ID...");
 Serial.println("iINSTRON_FUNDICION");
 */
}

void loop ()  {
  
 /*
 if (TurnDetected)  {        // do this only if rotation was detected
   if (up)
     virtualPosition++;
   else
     virtualPosition--;
   TurnDetected = false;          // do NOT repeat IF loop until new rotation detected
 */  
   //unsigned long currentTime = millis();
    static boolean newDataReady = 0;
  const int serialPrintInterval = 1000; //increase value to slow down serial print activity

   //Serial.print("grados = ");
 //  if((currentTime-previousTime)>=SAMPLE_RATE){
  //   previousTime = currentTime;
     /*
     //cell.update();
     Serial.print(-cell.getData());
     Serial.print(":");
     Serial.print(virtualPosition);
     Serial.print(":");
     Serial.print(currentTime/1000); //converting millis to seconds
     Serial.println();
     */
     //Serial.print("pulsos = ");
     //Serial.println(virtualPosition);
     // check for new data/start next conversion:

  
  
  if (cell.update()) newDataReady = true;

  // get smoothed value from the dataset:
  if (newDataReady) {
    if (millis() > t + serialPrintInterval) {
      float i = cell.getData();
      //Serial.print("Load_cell output val: ");
      Serial.print(i);
      Serial.print(":");
      Serial.print(virtualPosition);
      Serial.print(":");
      Serial.print(t/1000); //converting millis to seconds
      Serial.println();
      newDataReady = 0;
      t = millis();
    }
  }
  // }
}
