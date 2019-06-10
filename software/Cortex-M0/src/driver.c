/*
Author : Ludovic Moreau, Remi Dekimpe, UCL
				 Damien Deprez, UCL (2019)
*/

#include "driver.h"

// Peripherals
volatile unsigned short *gpin  = (volatile unsigned short *) 0x40001000U;
volatile unsigned short *gpout = (volatile unsigned short *) 0x40002000U;

// Peripherals "drivers"
void  send_enc_byte(char enc)  { *gpout = (GPOUT_ENCBYTE | enc); *gpout = 0x0000; }

void  send_signal_byte(char enc)  { *gpout = ((GPOUT_ENABLE << GPOUT_SINGAL_SHIFT) | enc); *gpout = 0x0000; }

void send_enc_2bytes(short value){
	*gpout = ( GPOUT_ENCBYTE | ((value>>8) & 0xFF));
	*gpout = ( GPOUT_ENCBYTE | ( value & 0xFF));
	*gpout = 0x0000;
}


// Implement file IO handling, only console output is supported.
int fputc(int ch, FILE *f)     { *gpout = ((GPOUT_ENABLE << GPOUT_PRINTF_SHIFT) | ch); *gpout = 0x0000; return ch; }
int ferror(FILE *f)            { return 0; }
int fgetc(FILE *f)             { return -1; }
