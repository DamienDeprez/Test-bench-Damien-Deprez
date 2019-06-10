# Test bench Damien Deprez
## Structure
- ``hardware`` directory : HDL code of the test bench, memory content and scripts for launching the behavioral simulation and the synthesis for each processor
- ``software`` directory : benchmark code for each processor and compiler script
- ``analyze`` directory : Python code for analyzing the memory access
- ``library`` directory : library file used for the synthesis

For each processor a README file explain how to run the compilation in the software directory and how to change the code executed during the behavioral simulation in the hardware directory. The HDL source code of the Cortex-M0 is not available.
