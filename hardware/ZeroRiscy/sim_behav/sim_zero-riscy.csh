
# Creating work library (Don't touch)

rm -r sim
mkdir sim

rm -r output
mkdir output

set workLib = workLib

rm -rf ${workLib}
valib ${workLib}


# PIXRACER

vlog ../src/hw/pixracer.v
vlog ../src/hw/data_bus.sv
vlog ../src/hw/data_memory.sv
vlog ../src/hw/instruction_memory.sv
vlog ../src/hw/gpio.v
vlog ../src/hw/ram.v
vlog ../src/hw/rom_nonsynth.v
vlog ../src/hw/cluster_clock_gating.sv
vlog ../src/hw/zero-riscy/include/zeroriscy_config.sv
vlog ../src/hw/zero-riscy/include/zeroriscy_defines.sv
vlog ../src/hw/zero-riscy/include/zeroriscy_tracer_defines.sv
vlog ../src/hw/zero-riscy/zeroriscy_alu.sv +incdir+../src/hw/zero-riscy/include
vlog ../src/hw/zero-riscy/zeroriscy_compressed_decoder.sv
vlog ../src/hw/zero-riscy/zeroriscy_controller.sv +incdir+../src/hw/zero-riscy/include
vlog ../src/hw/zero-riscy/zeroriscy_core.sv +incdir+../src/hw/zero-riscy/include
vlog ../src/hw/zero-riscy/zeroriscy_cs_registers.sv +incdir+../src/hw/zero-riscy/include
vlog ../src/hw/zero-riscy/zeroriscy_debug_unit.sv +incdir+../src/hw/zero-riscy/include
vlog ../src/hw/zero-riscy/zeroriscy_decoder.sv +incdir+../src/hw/zero-riscy/include
vlog ../src/hw/zero-riscy/zeroriscy_ex_block.sv +incdir+../src/hw/zero-riscy/include
vlog ../src/hw/zero-riscy/zeroriscy_fetch_fifo.sv +incdir+../src/hw/zero-riscy/include
vlog ../src/hw/zero-riscy/zeroriscy_id_stage.sv +incdir+../src/hw/zero-riscy/include
vlog ../src/hw/zero-riscy/zeroriscy_if_stage.sv +incdir+../src/hw/zero-riscy/include
vlog ../src/hw/zero-riscy/zeroriscy_int_controller.sv
vlog ../src/hw/zero-riscy/zeroriscy_load_store_unit.sv +incdir+../src/hw/zero-riscy/include
vlog ../src/hw/zero-riscy/zeroriscy_multdiv_fast.sv
vlog ../src/hw/zero-riscy/zeroriscy_prefetch_buffer.sv
vlog ../src/hw/zero-riscy/zeroriscy_register_file.sv +incdir+../src/hw/zero-riscy/include
vlog ../src/hw/zero-riscy/zeroriscy_tracer.sv +incdir+../src/hw/zero-riscy/include



# TESTER 

vlog  ../src/tbench/tester/tester.sv +incdir+../src/tbench/tester/


# TESTBENCH 

vlog ../src/tbench/tbench.v
vlog ../src/tbench/pcb_delay.v

# Launch the simulation
vasim tbench -c -do scripts/run_noVCD -t 100ps -outpath ./sim

#vcd2saif -input output/pixracer.vcd -output output/pixracer.saif
# Tool bug: An extra line is required so that the last command is executed.
