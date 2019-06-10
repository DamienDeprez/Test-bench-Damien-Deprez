/*
Author : Ludovic Moreau, Remi Dekimpe, UCL
				 Damien Deprez, UCL (2019)
*/


#ifndef DRIVER_H_
#define DRIVER_H_

//****************************************************************//
// INCLUDES
//****************************************************************//


#include <stdio.h>
#include <stdlib.h>

#include "ARMCM0.h"
#include "core_cm0.h"
#include <rt_heap.h>


//****************************************************************//
// DEFINES
//****************************************************************//

#define GPOUT_ENABLE		1
#define GPOUT_PRINTF_SHIFT 	9
#define GPOUT_ENCBYTE 0x100
#define GPOUT_SINGAL_SHIFT 10


// Peripherals
extern volatile unsigned short *gpin;
extern volatile unsigned short *gpout;

// Peripherals "drivers"

void  send_enc_byte(char enc);
void send_enc_2bytes(short value);

void  send_signal_byte(char enc);



// Implement file IO handling, only console output is supported.
int fputc(int ch, FILE *f);
int ferror(FILE *f);
int fgetc(FILE *f);


#endif
