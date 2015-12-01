typedef struct {
    uint8_t command;
    unsigned int pos;
    uint8_t cksum;
} Slave;

enum SlaveCommand {SLV_LOAD, SLV_SET_POS};


#define RS485Transmit    HIGH
#define RS485Receive     LOW

#include "timer.h"
#include "buttons.h"
#include "utils.h"
#include "pindefs.h"
#include <Encoder.h>
Encoder myEnc(ENCA,ENCB);
#include <SoftwareSerial.h>
SoftwareSerial master_serial(SS_RX, SS_TX); // RX, TX

const float mm_to_pulse = 35.3688;

volatile bool calc = false;

//pid globals
int pwm = 128;
#define MAX_POSREF 65535
unsigned int posref = 0;
float b0 = 0;
float b1 = 0;
float b2 = 0;
double yn = 0;
double ynm1 = 0;
float xn = 0;
float xnm1 = 0;
float xnm2 = 0;
float kp = .45;
float ki = 0.000;
float kd = .25;

void setup()
{
    buttons_setup();
    setup_timer2();
    Serial.begin(115200);
    master_serial.begin(57600); // 115200 too fast for reliable soft serial
    pinMode(LED, OUTPUT);

    pinMode(SSerialTxControl, OUTPUT);  
    digitalWrite(SSerialTxControl, RS485Receive);  // Init Transceiver

    pinMode(FOR, OUTPUT);
    digitalWrite(FOR,LOW);
    pinMode(REV, OUTPUT);
    digitalWrite(REV,LOW);


    // pid init
    b0 = kp+ki+kd;
    b1 = -kp-2*kd;
    b2 = kd;

    // turn on interrupts
    interrupts();
}

int bad_cksum = 0;
int ok = 0;

void loop()
{
    switch(buttons_check())
    {
        case IN:
            if(posref < MAX_POSREF)
                posref ++;
            delay(1);
            break;
        case OUT:
            if(posref > 0)
                posref --;
            delay(1);
            break;
        case HOME:
            while(buttons_check() != LIMIT)
                drive(HOME_PWM);
            drive(0);
            posref = 0;
            myEnc.write(0);
            break;
    }
    if(calc)
    {
        calc = false;
        digitalWrite(LED,HIGH);

        //pid calculation
        long newPosition = myEnc.read();
        xn = float(posref - newPosition);
        yn = ynm1 + (b0*xn) + (b1*xnm1) + (b2*xnm2);
        ynm1 = yn;

        //limit
        if(yn > 127)
            yn = 127;
        if(yn < -128)
            yn = -128;

        pwm = 128 + int(yn);   

        //write pwm values
        analogWrite(FOR,255-pwm);
        analogWrite(REV,pwm);

        //set previous input and output values
        xnm1 = xn;
        xnm2 = xnm1;
        digitalWrite(LED,LOW);
    }
    if(master_serial.available() >= sizeof(Slave))
    {
        Slave data;
        char buf[sizeof(Slave)];
        // do something with status?
        int status = master_serial.readBytes(buf, sizeof(Slave));

        //copy buffer to structure
        memcpy(&data, &buf, sizeof(Slave));
        //calculate cksum is ok
        if(data.cksum != CRC8(buf,sizeof(Slave)-1))
        {
            //ignore broken packet
            bad_cksum ++;
            //Serial.println("bad cksum");
            return;
        }
        ok ++;
        //Serial.println("ok!");
        //set the servo position
        switch(data.command)
        {
            case SLV_LOAD:
                //Serial.print("loaded:");
                //Serial.println(data.pos);
                posref = data.pos * mm_to_pulse;
                break;
            case SLV_SET_POS:
                //Serial.print("setpos:");
                //Serial.println(data.pos);
                posref = data.pos * mm_to_pulse;
                myEnc.write(posref);
                break;
        }
    }
    if(Serial.available())
    {
        char cmd = Serial.read();
        switch(cmd)
        {
            case 'a':
                Serial.println(ok);
                Serial.println(bad_cksum);
                break;
            case 'b':
                ok = 0;
                bad_cksum = 0;
                break;
        }
    }
}
