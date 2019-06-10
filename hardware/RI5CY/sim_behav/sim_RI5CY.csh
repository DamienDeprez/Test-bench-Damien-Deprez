
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
vlog ../src/hw/riscv/include/apu_core_package.sv
vlog ../src/hw/riscv/include/apu_macros.sv
vlog ../src/hw/riscv/include/riscv_config.sv
vlog ../src/hw/riscv/include/riscv_defines.sv
vlog ../src/hw/riscv/include/riscv_tracer_defines.sv
vlog ../src/hw/riscv/register_file_test_wrap.sv
vlog ../src/hw/riscv/riscv_alu_div.sv
vlog ../src/hw//riscv/riscv_alu.sv +incdir+../src/hw/riscv/include/
vlog ../src/hw/riscv/riscv_apu_disp.sv +incdir+../src/hw/riscv/include/
vlog ../src/hw/riscv/riscv_compressed_decoder.sv
vlog ../src/hw/riscv/riscv_controller.sv
vlog ../src/hw/riscv/riscv_core.sv +incdir+../src/hw/riscv/include/
vlog ../src/hw/riscv/riscv_cs_registers.sv
vlog ../src/hw/riscv/riscv_debug_unit.sv
vlog ../src/hw/riscv/riscv_decoder.sv +incdir+../src/hw/riscv/include/
vlog ../src/hw/riscv/riscv_ex_stage.sv +incdir+../src/hw/riscv/include/
vlog ../src/hw/riscv/riscv_fetch_fifo.sv
vlog ../src/hw/riscv/riscv_hwloop_controller.sv
vlog ../src/hw/riscv/riscv_hwloop_regs.sv
vlog ../src/hw/riscv/riscv_id_stage.sv
vlog ../src/hw/riscv/riscv_if_stage.sv
vlog ../src/hw/riscv/riscv_int_controller.sv
vlog ../src/hw/riscv/riscv_L0_buffer.sv
vlog ../src/hw/riscv/riscv_load_store_unit.sv
vlog ../src/hw/riscv/riscv_mult.sv
vlog ../src/hw/riscv/riscv_pmp.sv
vlog ../src/hw/riscv/riscv_prefetch_buffer.sv
vlog ../src/hw/riscv/riscv_prefetch_L0_buffer.sv
vlog ../src/hw/riscv/riscv_register_file.sv
vlog ../src/hw/riscv/riscv_tracer.sv
vlog ../src/hw/riscv/include/riscv_config.sv +incdir+../src/hw/riscv/include/


# TESTER

vlog  ../src/tbench/tester/tester.sv +incdir+../src/tbench/tester/


# TESTBENCH

vlog ../src/tbench/tbench.v
vlog ../src/tbench/pcb_delay.v

# Launch the simulation
vasim tbench -c -do scripts/run_noVCD -t 100ps -outpath ./sim

#vcd2saif -input output/pixracer.vcd -output output/pixracer.saif
# Tool bug: An extra line is required so that the last command is executed.
