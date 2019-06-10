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
../src/hw/zero-riscy/include/zeroriscy_config.sv
../src/hw/zero-riscy/include/zeroriscy_defines.sv
../src/hw/zero-riscy/zeroriscy_alu.sv
../src/hw/zero-riscy/zeroriscy_compressed_decoder.sv
../src/hw/zero-riscy/zeroriscy_controller.sv
../src/hw/zero-riscy/zeroriscy_core.sv
../src/hw/zero-riscy/zeroriscy_cs_registers.sv
../src/hw/zero-riscy/zeroriscy_debug_unit.sv
../src/hw/zero-riscy/zeroriscy_decoder.sv
../src/hw/zero-riscy/zeroriscy_ex_block.sv
../src/hw/zero-riscy/zeroriscy_fetch_fifo.sv
../src/hw/zero-riscy/zeroriscy_id_stage.sv
../src/hw/zero-riscy/zeroriscy_if_stage.sv
../src/hw/zero-riscy/zeroriscy_int_controller.sv
../src/hw/zero-riscy/zeroriscy_load_store_unit.sv
../src/hw/zero-riscy/zeroriscy_multdiv_fast.sv
../src/hw/zero-riscy/zeroriscy_prefetch_buffer.sv
../src/hw/zero-riscy/zeroriscy_register_file.sv
../src/hw/cluster_clock_gating.sv

} > reports/analyze.log

#####################################
#	Elaboration
#####################################

elaborate zeroriscy_core -architecture verilog -library DEFAULT > reports/elaborate.log
# HINT: if errors or warning upper, problems after

#####################################
#	Read SDC file
#####################################

source ../src/hw/zero-riscy.sdc > reports/read_sdc.log

check_design > reports/precheck.rpt

#####################################
#	Read switching activity file
#####################################

saif -start
saif_map -create_map -input ../sim_behav/output/pixracer.saif -source tbench/pixracer_0/zeroriscy_core_0 
saif_map -report > saif_map
read_saif -input ../sim_behav/output/pixracer.saif -instance tbench/pixracer_0/zeroriscy_core_0 -map_names -verbose
report_saif -hier > reports/report_activity

#####################################
#	Compilation
#####################################


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
report_power -analysis_effort low > reports/report_power.rpt
report_power -cell -analysis_effort low > reports/report_power_repartition.rpt
report_power -hier > reports/report_power_hier.rpt
report_reference -hierarchy > reports/report_reference.rpt
check_design > reports/check_post.rpt










