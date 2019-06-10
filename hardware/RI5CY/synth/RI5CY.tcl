#####################################
#	Configuration of Design Vision
#####################################

source ./config/synth.conf

#####################################
#	Analyze verilog source files
#####################################
#../src/hw/zero-riscy/include/zeroriscy_tracer_defines.sv
#vlog ../src/hw/zero-riscy/zeroriscy_tracer.sv

analyze -library WORK -format sverilog {
../src/hw/riscv/include/riscv_config.sv
../src/hw/riscv/include/riscv_defines.sv
../src/hw/riscv/include/apu_core_package.sv
../src/hw/riscv/include/apu_macros.sv
../src/hw/riscv/register_file_test_wrap.sv
../src/hw/riscv/riscv_alu.sv
../src/hw/riscv/riscv_alu_div.sv
../src/hw/riscv/riscv_apu_disp.sv
../src/hw/riscv/riscv_compressed_decoder.sv
../src/hw/riscv/riscv_controller.sv
../src/hw/riscv/riscv_core.sv
../src/hw/riscv/riscv_cs_registers.sv
../src/hw/riscv/riscv_debug_unit.sv
../src/hw/riscv/riscv_decoder.sv
../src/hw/riscv/riscv_ex_stage.sv
../src/hw/riscv/riscv_fetch_fifo.sv
../src/hw/riscv/riscv_hwloop_controller.sv
../src/hw/riscv/riscv_hwloop_regs.sv
../src/hw/riscv/riscv_id_stage.sv
../src/hw/riscv/riscv_if_stage.sv
../src/hw/riscv/riscv_int_controller.sv
../src/hw/riscv/riscv_L0_buffer.sv
../src/hw/riscv/riscv_load_store_unit.sv
../src/hw/riscv/riscv_mult.sv
../src/hw/riscv/riscv_pmp.sv
../src/hw/riscv/riscv_prefetch_buffer.sv
../src/hw/riscv/riscv_prefetch_L0_buffer.sv
../src/hw/riscv/riscv_register_file.sv
../src/hw/cluster_clock_gating.sv

} 


#####################################
#	Elaboration
#####################################

elaborate riscv_core -architecture verilog -library DEFAULT > reports/elaborate.log
# HINT: if errors or warning upper, problems after

#####################################
#	Read SDC file
#####################################

source ../src/hw/RI5CY.sdc > reports/read_sdc.log

check_design > reports/precheck.rpt

#####################################
#	Read switching activity file
#####################################

saif -start
saif_map -create_map -input ../sim_behav/output/pixracer.saif -source tbench/pixracer_0/riscv_core_0
read_saif -input ../sim_behav/output/pixracer.saif -instance tbench/pixracer_0/riscv_core_0 -map_names 
report_saif -hier > reports/report_activity

#####################################
#	Compilation
#####################################

### No clock gating ###
#compile_ultra -no_autoungroup > reports/compile.log
#######################

### Clock gating ###
compile_ultra -gate_clock -no_autoungroup > reports/compile.log
## Hold error not corrected during synthesis, delay on gated clock removed to fix simulation issue
#set_annotated_delay 0 -cell -to */clk_gate_*/main_gate/Z
#set_annotated_delay 0 -cell -to */*/clk_gate_*/main_gate/Z
####################

## Hold error not corrected during synthesis, delay on ICLK removed to fix simulation issue

#####################################
#	REPORT
#####################################

report_timing -path full -delay max -nworst 1 -max_paths 1 -significant_digits 2 -sort_by group  > reports/report_timing.rpt
report_area -nosplit > reports/report_area.rpt
report_power -analysis_effort high > reports/report_power.rpt
report_power -cell -analysis_effort high > reports/report_power_repartition.rpt
report_power -hier > reports/report_power_hier.rpt
report_reference -hierarchy > reports/report_reference.rpt
check_design > reports/check_post.rpt









