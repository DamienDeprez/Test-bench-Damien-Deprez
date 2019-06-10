/*
  Author : Deprez Damien, UCL (2019)
*/


#include "driver.h"

// Peripherals
volatile unsigned short *gpout = (volatile unsigned short *) 0x20002000;
volatile unsigned short *gpin = (volatile unsigned short *) 0x20001000;

/* Function : send_enc_byte
  Send a byte to the GPIO
*/
void  send_enc_byte(char enc)  { *gpout = (GPOUT_ENCBYTE | enc); *gpout = 0x0000; }

/* Function : send_signal_byte
  Send a signal to the GPIO with a value.
*/
void  send_signal_byte(char enc)  { *gpout = ((GPOUT_ENABLE << GPOUT_SINGAL_SHIFT) | enc); *gpout = 0x0000; }

/* Function : send_enc_int
  Send an integer to the GPIO
*/
void send_enc_int(int value){
	*gpout = ( GPOUT_ENCBYTE | ( value & 0x000000FF));
	*gpout = ( GPOUT_ENCBYTE | ((value & 0x0000FF00) >> 8));
	*gpout = ( GPOUT_ENCBYTE | ((value & 0x00FF0000) >> 16));
	*gpout = ( GPOUT_ENCBYTE | (value >> 24));
	*gpout = 0x0000;
}
