/*
  File : core_portme.c
*/
/*
  Author : Shay Gal-On, EEMBC
           Deprez Damien, UCL (2019)
  Legal : TODO!
*/
#include "coremark.h"

#if defined(VALIDATION_RUN) && VALIDATION_RUN == 1
  volatile ee_s32 seed1_volatile=0x3415;
  volatile ee_s32 seed2_volatile=0x3415;
  volatile ee_s32 seed3_volatile=0x66;
#endif
#if defined(PERFORMANCE_RUN) && PERFORMANCE_RUN == 1
  volatile ee_s32 seed1_volatile=0x0;
  volatile ee_s32 seed2_volatile=0x0;
  volatile ee_s32 seed3_volatile=0x66;
#endif
#if defined(PROFILE_RUN) && PROFILE_RUN == 1
  volatile ee_s32 seed1_volatile=0x8;
  volatile ee_s32 seed2_volatile=0x8;
  volatile ee_s32 seed3_volatile=0x8;
#endif
  volatile ee_s32 seed4_volatile=1; // number of iteration
  volatile ee_s32 seed5_volatile=0;
/* Porting : Timing functions
  How to capture time and convert to seconds must be ported to whatever is supported by the platform.
  e.g. Read value from on board RTC, read value from cpu clock cycles performance counter etc.
  Sample implementation for standard time.h and windows.h definitions included.
*/
/* Define : TIMER_RES_DIVIDER
  Divider to trade off timer resolution and total time that can be measured.

  Use lower values to increase resolution, but make sure that overflow does not occur.
  If there are issues with the return value overflowing, increase this value.
  */


/* Function :perf_read_cycle
  This function return the value inside the cycle counter of the processor
*/
int perf_read_cycle(void){
    int cycle;
    asm volatile ("csrr %0, 0X780" :"=r" (cycle));
    return cycle;
}

/* Function :perf_reset
  This function reset all value inside the performance counter of the processor
*/
void perf_reset(void){
    unsigned int value = 0;
    asm volatile ("csrw 0x780, %0" :"=r" (value));
}

/* Function :perf_read_cycle
  This function initialize the performance counter of the processor with a mask
  for selecting witch counter is enable
*/
void perf_init(void){
    unsigned int eventMask = 0x1;
    asm volatile ("csrw 0x7A0, %0" :"+r" (eventMask));
}



#define NSECS_PER_SEC CLOCKS_PER_SEC
#define CORETIMETYPE int
#define GETMYTIME(_t) (*_t=perf_read_cycle())
#define MYTIMEDIFF(fin,ini) ((fin)-(ini))
#define TIMER_RES_DIVIDER 1
#define SAMPLE_TIME_IMPLEMENTATION 1
#define EE_TICKS_PER_SEC (NSECS_PER_SEC / TIMER_RES_DIVIDER)

/** Define Host specific (POSIX), or target specific global time variables. */
static CORETIMETYPE start_time_val, stop_time_val;

/* Function : start_time
  This function will be called right before starting the timed portion of the benchmark.

  Implementation may be capturing a system timer (as implemented in the example code)
  or zeroing some system parameters - e.g. setting the cpu clocks cycles to 0.
*/
void start_time(void) {
  start_time_val = perf_read_cycle();
  send_enc_int(start_time_val);
  start_time_val = perf_read_cycle();
}

/* Function : stop_time
  This function will be called right after ending the timed portion of the benchmark.

  Implementation may be capturing a system timer (as implemented in the example code)
  or other system parameters - e.g. reading the current value of cpu cycles counter.
*/
void stop_time(void) {
    stop_time_val = perf_read_cycle();
    send_enc_int(stop_time_val);
}
/* Function : time_in_secs
  Convert the value returned by get_time to seconds.

  The <secs_ret> type is used to accomodate systems with no support for floating point.
  Default implementation implemented by the EE_TICKS_PER_SEC macro above.
*/
secs_ret time_in_secs(CORE_TICKS ticks) {
  secs_ret retval=((secs_ret)ticks) / (secs_ret)EE_TICKS_PER_SEC;
  return retval;
}

CORE_TICKS get_time(void) {
        CORE_TICKS elapsed=(CORE_TICKS)(MYTIMEDIFF(stop_time_val, start_time_val));
        return elapsed;
}

/* Function : time_in_secs
  Convert the value returned by get_time to seconds.

  The <secs_ret> type is used to accomodate systems with no support for floating point.
  Default implementation implemented by the EE_TICKS_PER_SEC macro above.
*/
secs_ret time_in_usecs(CORE_TICKS ticks) {
  secs_ret retval= (secs_ret)(1000000 * (float)ticks / EE_TICKS_PER_SEC);
  return retval;
}

ee_u32 default_num_contexts=MULTITHREAD;

/* Function : portable_init
  Target specific initialization code
  Test for some common mistakes.
*/
void portable_init(core_portable *p, int *argc, char *argv[])
{

	perf_init();
	perf_reset();

  p->portable_id=1;
}
/* Function : portable_fini
  Target specific final code
*/
void portable_fini(core_portable *p)
{
  p->portable_id=0;
}

ee_u8 core_start_parallel(core_results *res) {
  iterate(res);
  return 0;
}
ee_u8 core_stop_parallel(core_results *res) {
  return 0;
}
