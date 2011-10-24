#include <TimedAction.h>

/*
nhs hull starter code
Matt Venn 2011 for Jam Jar Collective


  Hull NHS Colour-facade control code

  Developed by Adrian McEwen and Stuart Childs to monitor the
  light levels and outside temperature, and when it's dark light
  up different light colours based on the temperature

*/

//pin defs
#define RELAY1 2
#define RELAY2 3
#define RELAY3 4
#define RELAY4 5

#define TEMP A0
#define LDR A1

#define LEDS1 A2 //  R
#define LEDS2 A5 //  G
#define LEDS3 A3 //  B
#define LEDS4 A4 //  Y

#define LED_GREEN 13
#define LED_RED 12

//globals
unsigned int light, temp;
const int averageArrayLength = 30;
unsigned int rawTempArray [averageArrayLength];
unsigned int rawLightArray [averageArrayLength];

boolean LED_OK = false;

boolean testCycle = false;
int minute = 0;
int updateLightMinutes = 15;

TimedAction statusAction = TimedAction(500,blink);
TimedAction updateElectricalAction = TimedAction(5000,updateElectrical);
TimedAction outputTestAction = TimedAction(10000,testAllOutputs);
TimedAction updateLightsAction = TimedAction(60000,updateLights); //once per minute 60000


#define INIT_LIGHT_SEQUENCE 1

//defs from Adrian's code
bool gLightsOn = false;
const int kDuskThreshold = 270;
// Theshold at which we think it's getting light again
const int kDawnThreshold = 350;

// Number of seconds to wait between colour changes in the initial "it's gone dark, cycle through all possibilities" sequence
const unsigned long kInitialLightSequenceDelay = 5;


/*sensor value is 500mv + 10mv * degrees C. 
low val = -7 so 500mv - 10*7mv = 430. 430 / (5000/1024) = 88
high val = 15 so 500mv + 10*15 = 650. 650 / (5000/1024) = 133
high day val = 30 so 500mv + 30*10 = 800. 800 / (5000/1024) = 163
*/
// Minimum value (NOT temperature) that the temperature sensor will read 
const int kMinTempValue = 88;
// Maximum value from analogRead that the temperature sensor will provide
const int kMaxNightTempValue = 133;
const int kMaxDayTempValue = 163;

// Bits for the setLights number to color pattern mapping
const int kLightsOff = 0;
const int kRedBit = 1 << 0;
const int kGreenBit = 1 << 1;
const int kBlueBit = 1 << 2;
const int kYellowBit = 1 << 3;
const int kLightsOn = kRedBit | kGreenBit | kBlueBit | kYellowBit;

const int kTempIntervalCount = 15;
const int kTempMap[kTempIntervalCount] = {
 kRedBit,
 kYellowBit,
 kGreenBit,
 kBlueBit,
 kRedBit | kYellowBit,
 kRedBit | kGreenBit,
 kRedBit | kBlueBit,
 kYellowBit | kGreenBit,
 kYellowBit | kBlueBit,
 kGreenBit | kBlueBit,
 kRedBit | kYellowBit | kGreenBit,
 kRedBit | kYellowBit | kBlueBit,
 kRedBit | kGreenBit | kBlueBit,
 kYellowBit | kGreenBit | kBlueBit,
 kRedBit | kYellowBit | kGreenBit | kBlueBit
};




void setup() {                
  // initialize the digital pin as an output.
  // Pin 13 has an LED connected on most Arduino boards:
  pinMode(LED_GREEN, OUTPUT);     
  pinMode(LED_RED, OUTPUT);     
  pinMode(LED_GREEN, OUTPUT);   
  pinMode(LEDS1, OUTPUT);
  pinMode(LEDS2, OUTPUT);
  pinMode(LEDS3, OUTPUT);
  pinMode(LEDS4, OUTPUT);
  pinMode(RELAY1, OUTPUT);
  pinMode(RELAY2, OUTPUT);
  pinMode(RELAY3, OUTPUT);
  pinMode(RELAY4, OUTPUT);

  initialiseAvgArray( rawTempArray, averageArrayLength );
  initialiseAvgArray( rawLightArray, averageArrayLength );
  Serial.begin(9600);
  Serial.println("nhs hull starting...");


}


void loop()
{
  outputTestAction.check(); //turns all relay and LED channels on and off every 2 seconds
  updateElectricalAction.check(); //updates the data from the sensors
  statusAction.check(); //blinks the green light so we know everything is still running
//  updateLightsAction.check(); //do the pretty stuff
}

void updateLights()
{
 if (minute ++ <= updateLightMinutes )
   return;
 minute = 0;
 Serial.println( "update lights called" );


 if ((light < kDuskThreshold) && (gLightsOn == false))
 {
   // It's gone dark
   gLightsOn = true;

   // When it first goes dark, we cycle through all the light combinations
   #ifdef INIT_LIGHT_SEQUENCE
   for (int i = 0; i < 16; i++)
   {
     setLights(kTempMap[i]);
     delay(1000UL * kInitialLightSequenceDelay);
   }
   #endif
 }
 else if (light > kDawnThreshold)
 {
   // It's light again
   gLightsOn = false;
 }

 Serial.print( "glightsOn: " );
 Serial.println( gLightsOn ? "true" : "false" );
  
   // Map this temperature value to  
   int maxTempValue = gLightsOn ? kMaxNightTempValue : kMaxDayTempValue;
   int tempValue = constrain(temp, kMinTempValue, maxTempValue );
   int i = map(tempValue, kMinTempValue, maxTempValue, 0, kTempIntervalCount-1);
   Serial.print( "tempMap: " );
   Serial.println( i );
   setLights(kTempMap[i]);
  
}

void blink()
{
  digitalWrite(LED_GREEN, LED_OK );
  LED_OK = ! LED_OK;
}

void updateElectrical()
{
  int lightRaw = analogRead( LDR );
  delay(50);
  lightRaw = analogRead( LDR );
  int tempRaw = analogRead( TEMP );
  delay(50);
  tempRaw = analogRead( TEMP );

  //average to get rid of noise
  light = getAverage( lightRaw, rawLightArray, averageArrayLength );
  temp = getAverage( tempRaw, rawTempArray, averageArrayLength );
  Serial.print( "light: " );
  Serial.print( lightRaw );
  Serial.print( " -> " );
  Serial.println( light);
  Serial.print( "temp: " );
  Serial.print( tempRaw ); 
  Serial.print( " -> " );
  Serial.println( temp );
  

}
void testAllOutputs() {
  
  //invert state
  testCycle = ! testCycle;
 
  digitalWrite(LEDS1, testCycle);   
  digitalWrite(RELAY1, testCycle);   
  
  digitalWrite(LEDS2, testCycle);  
  digitalWrite(RELAY2, testCycle); 

  digitalWrite(RELAY3, testCycle);  
  digitalWrite(LEDS3, testCycle); 
  
  digitalWrite(LEDS4, testCycle);   
  digitalWrite(RELAY4, testCycle); 
  
  digitalWrite(LED_RED, testCycle );
}


// setLights
// Function to turn the lights on based on the provided aLightMask.
// aLightMask should be a number between 0 (all off) and 15 (all on)
// with each bit of that 4-bit number referring to a particular colour
// (see the kXxxBit constants to find out which bit is which colour)
void setLights(int aLightMask)
{
 //do this all the time

 digitalWrite(LEDS1, aLightMask & kRedBit ); 
 digitalWrite(LEDS2, aLightMask & kGreenBit);
 digitalWrite(LEDS3, aLightMask & kBlueBit);
 digitalWrite(LEDS4, aLightMask & kYellowBit);
 
 //only control main lights if it's dark
 if( gLightsOn )
 {
   digitalWrite(RELAY1, aLightMask & kRedBit);
   digitalWrite(RELAY2, aLightMask & kGreenBit);
   digitalWrite(RELAY3, aLightMask & kBlueBit);
   digitalWrite(RELAY4, aLightMask & kYellowBit);
 }
 else
 {
   digitalWrite(RELAY1, LOW );
   digitalWrite(RELAY2, LOW );
   digitalWrite(RELAY3, LOW );
   digitalWrite(RELAY4, LOW );
 }   
}
