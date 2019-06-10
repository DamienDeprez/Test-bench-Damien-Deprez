

#####################################
#                                   #
#      Timing in active mode        #
#                                   #
#####################################

set CLK_PERIOD  	12.5
set TCK_PERIOD 		200
set ICLK_DIVISION	6

set MAX_IO_DLY		0
set MIN_IO_DLY		0

set UNCERTAINTY		0.5

#####################################
#                                   #
#      		Main clocks		   	 	#
#                                   #
#####################################

# HCLK for the whole SoC
create_clock -name "clk_i" -period "$CLK_PERIOD" -waveform "0 [expr $CLK_PERIOD/2]" [get_ports clk_i]

set_clock_uncertainty $UNCERTAINTY 	[all_clocks]

#####################################
#                                   #
#         BOUNDARY CONDITIONS	    #
#                                   #
#####################################

set_driving_cell -lib_cell C8T28SOI_LL_AND2X5_P16 -library C28SOI_SC_8_COREPBP16_LL_TT_0.40V_0.00V_1.00V_-2.00V_25C [all_inputs]
#set_driving_cell -lib_cell HS65_LS_IVX4 -library CORE65LPSVT [all_inputs]
set_load -pin_load 0.001 [all_outputs]

#####################################
#                                   #
#         INPUT/OUPUT DELAYS	    #
#                                   #
#####################################


# SCK-related SPI I/Os

set_input_delay 	-max [expr $MAX_IO_DLY] 				-clock "clk_i"	[all_inputs]
set_input_delay 	-min [expr -$MAX_IO_DLY] 				-clock "clk_i" 	[all_inputs]
set_output_delay 	-max [expr $MAX_IO_DLY] 				-clock "clk_i"	[all_outputs]
set_output_delay 	-min [expr -$MAX_IO_DLY] 				-clock "clk_i" 	[all_outputs]








