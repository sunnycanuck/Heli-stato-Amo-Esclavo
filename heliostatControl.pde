/* a program to control the heliostat h-bridge motor drivers
 
  by Rodger Evans, 2010-11-11
  sunnycanuck@gmail.com
  Published under the Creative Commons 'share a like" licence
  
*/

#include <Bounce.h> 
  
int PHIup=10; //Digital Pin for Phi up button and LED
int PHIdown=6;//  "      "    "  "  down  "    "   "
int THETAleft=5;
int THETAright=9;

int center=11; //LED outputs not connected to buttons
int BTTNcenter=13; //center button, can be used as an interupt

int HBphiPWMH=4; //digital outputs to the h-bridge.
int HBphiDIR=7;
int HBthetaPWMH=8;
int HBthetaDIR=12;

int phiPWMH; //values to be sent to the h-bridge
int phiDIR;
int thetaPWMH;
int thetaDIR;

int sensor= 3;
int a1= 4;
int a3= 5;
int sensorPower=11; //this is the signal to send power to the voltage divider that is the photo sensors
                    //this pin also powers the center LED  
int deltaPHI=10; //delta___ is the amount off of the center value that will give a misaligned signal 
int deltaTHETA=10;
volatile int AvgSensorValue;
volatile int AvgDivider1;
volatile int AvgDivider2;

int CENTsensorPhi=200; //the center value from the sensors (starting in 200, this should be checked)
int CENTsensorTheta=200;
//int sensorPhi; //the value read off the sensors
//int sensorTheta;
  
int modeLED = 3; //the output pin to the LED indicating mode
volatile int mode = HIGH; //mode=HIGH is the manual mode (red LED lit)

volatile int UP;//direction values to be sent to hBridge routeen
volatile int DOWN;
volatile int LEFT;
volatile int RIGHT;
int CENTER;

/*boolean uup=false; //boolean to be used in the hbridge command
boolean ddown=false;
boolean lleft=false;
boolean rright=false;*/

Bounce bPHIup = Bounce( PHIup, 20 );
Bounce bPHIdown = Bounce( PHIdown, 20 );
Bounce bTHETAleft = Bounce( THETAleft, 20 );
Bounce bTHETAright = Bounce( THETAright, 20 );
Bounce bBTTNcenter = Bounce( BTTNcenter, 20 );

void setup()
{
  pinMode(modeLED, OUTPUT); //sets the modeLED pin to output
  attachInterrupt(0, my_interrupt_handler, RISING);//the inturrupt for the mode change
//  attachInterrupt(1, centerSensor, RISING);//the inturrupt for the mode change
  
  pinMode(HBphiPWMH, OUTPUT);
  pinMode(HBphiDIR, OUTPUT);
  pinMode(HBthetaPWMH, OUTPUT);
  pinMode(HBthetaDIR, OUTPUT);
  
  pinMode(BTTNcenter, INPUT);
  pinMode(sensorPower, OUTPUT);     
  Serial.begin(9600); 
}

void loop()
{
  digitalWrite(modeLED, mode); //illuminate the mode LED (HIGH=red (manual); LOW=green (auto))
  if (mode==HIGH){//manual mode
    //read the buttons and make DIR and PHWM cammonds
    PinInput();
    
    //update the debounced signal from the buttons (set in the my_interrupt_handler and PinInput functions)
    bPHIup.update ( );  
    bPHIdown.update ( );
    bTHETAleft.update ( );
    bTHETAright.update ( );
    bBTTNcenter.update ( );
    
    UP = bPHIup.read(); //UP, DOWN, LEFT, RIGHT, are HIGH/LOW values depeding on the buttons being pushed
    DOWN = bPHIdown.read();
    LEFT = bTHETAleft.read();
    RIGHT = bTHETAright.read();  
    CENTER = bBTTNcenter.read();
    
    if (CENTER==HIGH){
     readSensor();
     CENTsensorPhi= AvgDivider1;
     CENTsensorTheta= AvgDivider2;
     
      Serial.print(CENTsensorPhi);
      Serial.print(" ");
      Serial.print(CENTsensorTheta);
      Serial.println(" ");
     
    }
    
//    if ((UP==HIGH) || (DOWN==HIGH) || (LEFT==HIGH) || (RIGHT==HIGH)){

//    }

  }
  if (mode==LOW){//automatic mode; read sensors to get PWHM and DIR
    PinOutput();
    
   readSensor(); 
    
   if (AvgDivider1>CENTsensorPhi+deltaPHI){
   UP=HIGH;
   DOWN=LOW; 
   digitalWrite(PHIup ,HIGH);
   digitalWrite(PHIdown ,LOW);
  }
  else if (AvgDivider1< CENTsensorPhi-deltaPHI){
    UP=LOW;
    DOWN=HIGH;
    digitalWrite(PHIup ,LOW);
    digitalWrite(PHIdown ,HIGH);
  }
  else{
    UP=LOW;
    DOWN=LOW;
    digitalWrite(PHIup ,LOW);
    digitalWrite(PHIdown ,LOW);
  }

  if (AvgDivider2>CENTsensorTheta+deltaTHETA){
   LEFT=HIGH;
   RIGHT=LOW; 
   digitalWrite(THETAleft ,HIGH);
   digitalWrite(THETAright ,LOW);
  }
  else if (AvgDivider2< CENTsensorTheta-deltaTHETA){
    LEFT=LOW;
    RIGHT=HIGH;
    digitalWrite(THETAleft ,LOW);
    digitalWrite(THETAright ,HIGH);
  }
  else{
    LEFT=LOW;
    RIGHT=LOW;
    digitalWrite(THETAleft ,LOW);
    digitalWrite(THETAright ,LOW);
  }  
  }
  
  HbridgeCommannd(UP, DOWN, LEFT, RIGHT); //send the direction commands to the H-bridge
}


void my_interrupt_handler() //the interrupt function
{
  static unsigned long last_interrupt_time = 0; //sets the time since the last interrupt
  unsigned long interrupt_time = millis(); //time of current interrupt
  // If interrupts come faster than 200ms, assume it's a bounce and ignore
  if (interrupt_time - last_interrupt_time > 200)
  {
    mode = !mode; //if the button was pushed, then change the mode setting
    if (mode==HIGH){//MANUAL
     PinInput(); 
    }
    if (mode==LOW){//AUTOMATIC MODE
     PinOutput();
    }
  }
  last_interrupt_time = interrupt_time; //set the current interrupt time to be the last one
} 

/*void centerSensor() //the interrupt function
{
  static unsigned long last_interrupt_time = 0; //sets the time since the last interrupt
  unsigned long interrupt_time = millis(); //time of current interrupt
  // If interrupts come faster than 200ms, assume it's a bounce and ignore
  if (interrupt_time - last_interrupt_time > 200)
  {
    
  }
  last_interrupt_time = interrupt_time; //set the current interrupt time to be the last one
} */

void PinInput(){//this turns the digital pins to inputs, and sets up the debounce
//it is used for auto
  pinMode(PHIup,INPUT);
  pinMode(PHIdown,INPUT);
  pinMode(THETAleft,INPUT);
  pinMode(THETAright,INPUT);
  
//  Bounce bPHIup = Bounce( PHIup, 20 );
//  Bounce bPHIdown = Bounce( PHIdown, 20 );
//  Bounce bTHETAleft = Bounce( THETAleft, 20 );
//  Bounce bTHETAright = Bounce( THETAright, 20 );
}

void PinOutput(){//this turns the digital pins to outputs 
//it is used for Automatic
  pinMode(PHIup,OUTPUT);
  pinMode(PHIdown,OUTPUT);
  pinMode(THETAleft,OUTPUT);
  pinMode(THETAright,OUTPUT);
}

//this takes the direction commands, converts and sends signals to the Hbridge
void HbridgeCommannd(boolean upp,boolean downn,boolean leftt,boolean rightt){
  
  phiPWMH=(UP || DOWN) && !(UP && DOWN);
  phiDIR= UP && ! DOWN;
  
  thetaPWMH=(LEFT || RIGHT) && !(LEFT && RIGHT);
  thetaDIR=LEFT && ! RIGHT;

      Serial.print(phiPWMH);
      Serial.print(" ");
      Serial.print(phiDIR);
      Serial.print(" ");
      Serial.print(thetaPWMH);
      Serial.print(" ");
      Serial.println(thetaDIR);
  
  digitalWrite (HBphiPWMH, phiPWMH);
  digitalWrite (HBphiDIR, phiDIR);
  
  digitalWrite (HBthetaPWMH, thetaPWMH);
  digitalWrite (HBthetaDIR, thetaDIR);
  delay(500);
}

void readSensor(){
  
//the next 6 lines should maybe be in a loop that repeats to get an average signal
  int counter=0;
  int finalCounter=3; //the amount of averages

  int divider1[finalCounter];
  int divider2[finalCounter];
  int sensorValue[finalCounter];
  
//  int divider1;
//  int divider2;
//  int sensorValue;
  
  while (counter < finalCounter){//a loop with measurements is made ever 0.5 seconds

    digitalWrite(sensorPower, HIGH);  //POWER sensor board
    delay(200);
  
   // sensorValue[counter] = analogRead(sensor);     // read analog inputs
  //  divider1[counter] = analogRead(a1);
   // divider2[counter] = analogRead(a3);
   
    sensorValue[counter] = analogRead(sensor);     // read analog inputs
    divider1[counter] = analogRead(a1);
    divider2[counter] = analogRead(a3);
   
    digitalWrite(sensorPower, LOW); //  turn off board

    delay(300);              // wait 300ms for next reading
   
    AvgSensorValue=AvgSensorValue+sensorValue[counter];
    AvgDivider1=AvgDivider1+divider1[counter];
    AvgDivider2=AvgDivider2+divider2[counter];
   // AvgSensorValue=AvgSensorValue+sensorValue;
   // AvgDivider1=AvgDivider1+divider1;
   // AvgDivider2=AvgDivider2+divider2;
    
     counter++;
  }

  AvgDivider1=AvgDivider1/finalCounter;
  AvgDivider2=AvgDivider2/finalCounter;
  AvgSensorValue=AvgSensorValue/finalCounter;
  
  Serial.print(AvgSensorValue, DEC);  // prints the value read
  Serial.print(" ");	   // prints a space between the numbers

  Serial.print(AvgDivider1, DEC);  // prints the value read
  Serial.print(" ");	   // prints a space between the numbers

  Serial.print(AvgDivider2, DEC);  // prints the value read
  Serial.println(" ");	   // prints a space between the numbers and new line
}

/*void centerSensor(){
//the next 6 lines should maybe be in a loop that repeats to get an average signal, 
//checking to make sure it is not flucuating quickly  
  digitalWrite(sensorPower, HIGH);   // set the LED on

  sensorPhi = analogRead(A0);
  sensorTheta = analogRead(A1);
  Serial.println(sensorPhi, DEC);
  Serial.println(sensorTheta, DEC);  

  digitalWrite(13, LOW);    // set the LED off
 
  CENTsensorPhi=sensorPhi;
  CENTsensorTheta=sensorTheta;
  
}*/

