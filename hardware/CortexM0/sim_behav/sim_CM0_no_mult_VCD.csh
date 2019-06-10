
# Creating work library (Don't touch)

rm -r sim
mkdir sim

set workLib = workLib

rm -rf ${workLib}
valib ${workLib}


# PIXRACER

vlog ../src/hw/pixracer.v
vlog ../src/hw/ahb_slave_mux.sv
vlog ../src/hw/gpio.v
vlog ../src/hw/spi_master.v
vlog ../src/hw/ram.v
vlog ../src/hw/memory.v
vlog ../src/hw/rom_nonsynth.v
vlog ../src/hw/CORTEXM0DS/CORTEXM0DS.v
vlog ../src/hw/CORTEXM0DS/cortexm0ds_logic.v 

# TESTER 

vlog  ../src/tbench/tester/tester.sv +incdir+../src/tbench/tester/


# TESTBENCH 

vlog ../src/tbench/tbench.v
vlog ../src/tbench/pcb_delay.v

# Launch the simulation
vasim tbench -c -do scripts/run -t 100ps -outpath ./sim

vcd2saif -input output/pixracer.vcd -output output/pixracer_no_mult.saif

rm output/pixracer.vcd

# Tool bug: An extra line is required so that the last command is executed.
