#####################################
#	Configuration of Design Vision
#####################################

source ./config/synth.conf

#####################################
#	Analyze verilog source files
#####################################

analyze -library WORK -format verilog {
../src/hw/CortexM0/CORTEXM0DS.v
../src/hw/CortexM0/cortexm0ds_logic.v} > reports/analyze-O3M.log


#####################################
#	Elaboration
#####################################

elaborate CORTEXM0DS -architecture verilog -library DEFAULT > reports/elaborate-O3M.log
# HINT: if errors or warning upper, problems after

#####################################
#	Read SDC file
#####################################

source ../src/hw/cortexm0.sdc > reports/read_sdc.log

check_design > reports/precheck.rpt

#####################################
#	Read switching activity file
#####################################

saif -start
saif_map -create_map -input ../sim_behav/output/pixracer-O3M.saif -source tbench/pixracer_0
read_saif -input ../sim_behav/output/pixracer-O3M.saif -instance tbench/pixracer_0 -map_names 
report_saif -hier > reports/report_activity-O3M.log

#####################################
#	Compilation
#####################################

### No clock gating ###
#compile_ultra -no_autoungroup > reports/compile-O3M.log
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

report_timing -path full -delay max -nworst 1 -max_paths 1 -significant_digits 2 -sort_by group  > reports/report_timing-O3M.rpt
report_area -nosplit > reports/report_area-O3M.rpt
report_power -analysis_effort low > reports/report_power-O3M.rpt
report_power -cell -analysis_effort low > reports/report_power_repartition-O3M.rpt
report_power -hier > reports/report_power_hier-O3M.rpt
report_reference -hierarchy > reports/report_reference-O3M.rpt
check_design > reports/check_post-O3M.rpt








