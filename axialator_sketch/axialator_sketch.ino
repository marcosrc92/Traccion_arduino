#include <HX711_ADC.h>


//#include "HX711.h"

//LOS PINES SON ESTOS:
//celula de carga
const int DOUT = A0;
const int CLK = A1;
//encoder
const int PinCLK=3;                   // Used for generating interrupts using CLK signal
const int PinDT=2;                    // Used for reading DT signal



//A PARTIR DE AQUI ES EL FUNCIONAMIENTO, NO TOCAR.
#define SAMPLE_RATE 1000 //sample every SAMPLE_RATE ms

HX711_ADC cell(DOUT,CLK);

volatile boolean TurnDetected;
volatile boolean up;
static long virtualPosition=0;    // without STATIC it does not count correctly!!!

unsigned long previousTime = 0.0;

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
 //set new calibration factor, raw data is divided by this value to convert to readable data modifica "calFactorRecip"
 cell.setCalFactor(1171.6);

 //set new tare offset (raw data value input without the scale "calFactor")
 cell.setTareOffset(5000);
 /***************************************************************************/ 
 
 Serial.begin (115200);
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
   
   unsigned long currentTime = millis();
   //Serial.print("grados = ");
   if((currentTime-previousTime)>=SAMPLE_RATE){
     previousTime = currentTime;
     cell.update();
     Serial.print(-cell.getData());
     Serial.print(":");
     Serial.print(virtualPosition);
     Serial.print(":");
     Serial.print(currentTime/1000); //converting millis to seconds
     Serial.println();
     //Serial.print("pulsos = ");
     //Serial.println(virtualPosition);
   }
}
