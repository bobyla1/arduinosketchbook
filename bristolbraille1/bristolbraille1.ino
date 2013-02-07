//setup for stepper motor (our motor is 3.6degree)
#define STEPS 200
#include <Stepper.h>
Stepper stepper(STEPS, 2,3,4,5);

//led
#define LED 13

//define solenoid pins
#define SOLENOID1 6
#define SOLENOID2 8
#define SOLENOID3 7

int offset = 0;

//what to do at the start
void setup()
{
  Serial.begin(9600);
//  Serial.println( "started" );
  // set the speed of the motor (RPMs)
  stepper.setSpeed(20); //40 works
  
  //pin modes of the control pins
  pinMode(LED,OUTPUT);
  pinMode(SOLENOID1,OUTPUT);
  pinMode(SOLENOID2,OUTPUT);
  pinMode(SOLENOID3,OUTPUT);
}

//keep doing this
void loop()
{
  if( Serial.available() )
  {
    char c = Serial.read();
    switch( c )
    {
      case 'r': //reset
        reset_clips();
                Serial.println("ok");
        break;
      case 's': //set
      {
        delay(100); //wait for numbers to come in
        
        set(serReadInt(),serReadInt(),serReadInt());
                Serial.println("ok");
        break;
      }
      case 'f': //rotate forward
        delay(100);
        stepper.step(serReadInt());
        Serial.println("ok");
        break;        
      case 'o': //set offset
        offset = serReadInt();
        Serial.print("set offset to ");
        Serial.println(offset);
        Serial.println("ok");
        break;
      case 'm': //set motor speed
        stepper.setSpeed(serReadInt());
        Serial.println("set stepper speed");
        Serial.println("ok");
        break;
      default:
        Serial.println("bad command");
        break;
    }
  }
}

void set(int sol1, int sol2, int sol3)
{
  Serial.println("setting solenoids to: ");
  Serial.print(sol1); Serial.print(","); Serial.print(sol2); Serial.print(","); Serial.println(sol3);
  
  sol1 = map(sol1, 0, 8, 0, STEPS);
  sol2 = map(sol2, 0, 8, 0, STEPS);
  sol3 = map(sol3, 0, 8, 0, STEPS);
  
    Serial.print(sol1); Serial.print(","); Serial.print(sol2); Serial.print(","); Serial.println(sol3);
  //during a whole turn, fire the solenoids on their random trigger point
  
  for( int stepNum =0; stepNum < STEPS; stepNum ++ )
  {
   
    //check if we need to turn on the solenoid
    if( stepNum + offset >= sol1 )
      digitalWrite(SOLENOID1,HIGH);
    if( stepNum + offset >= sol2 )
      digitalWrite(SOLENOID2,HIGH);
    if( stepNum + offset >= sol3 )
      digitalWrite(SOLENOID3,HIGH);
      
      
    //take one step on the motor
    stepper.step(1);
  }
  
   //turn off the solenoids
  digitalWrite(SOLENOID1,LOW);
  digitalWrite(SOLENOID2,LOW);
  digitalWrite(SOLENOID3,LOW);
}

void reset_clips()
{
  //turn motor back
  stepper.step(-100);
  stepper.step(8);
}

void flash(int pin, int delayT)
{
  digitalWrite(pin,HIGH);
  delay(delayT);
  digitalWrite(pin,LOW);
}


