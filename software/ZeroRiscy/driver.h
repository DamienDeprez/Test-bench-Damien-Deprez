#ifndef DRIVER_H_
#define DRIVER_H_

//****************************************************************//
// INCLUDES 													  
//****************************************************************//


//#include <stdio.h>
//#include <stdlib.h>

/*#include "ARMCM0.h"
#include "core_cm0.h"
#include <rt_heap.h>*/


//****************************************************************//
// DEFINES 
//****************************************************************//

#define SPI_IRQ				0
#define GPIN_IRQ			1

#define GPOUT_ENABLE		1
#define GPOUT_PRINTF_SHIFT 	9
#define GPOUT_ENCBYTE 0x100 
#define GPOUT_SINGAL_SHIFT 10


// Peripherals
extern volatile unsigned short *gpout;
extern volatile unsigned short *gpin;


void  send_enc_byte(char enc);
void send_enc_int(int value);

void  send_signal_byte(char enc);



#endif /* ELEC2570_CM0_SW_H_*/
