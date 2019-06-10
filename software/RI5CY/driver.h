#ifndef DRIVER_H_
#define DRIVER_H_

//****************************************************************//
// DEFINES
//****************************************************************//

#define GPOUT_ENCBYTE 0x100
#define GPOUT_SINGAL_SHIFT 10


// Peripherals
extern volatile unsigned short *gpout;
extern volatile unsigned short *gpin;


void  send_enc_byte(char enc);
void send_enc_int(int value);
void  send_signal_byte(char enc);

#endif
