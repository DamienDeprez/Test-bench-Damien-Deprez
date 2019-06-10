# Source code of the test bench
The source code of the test bench is in the ``src`` directory. This directory is divided in three part :
- the source code of the processor, the transfert bus, the memories and the peripherals in the ``hw`` directory,
- the memories contents in the ``sw`` directory,
- the test bench source code for the behavioral simulation in the ``tbench`` directory.

The content of the ``sw`` directory is the output of the compilation. For changing the code executed on the processor during the behavioral simulation, we need to change the ``rom_nonsynth.v`` file in the ``hw`` directory. For the ``rom_nonsynth.v`` file you have to modify the line  ``$readmemh("./../src/sw/code-O3.hex", mem);``.

# Behavioral simulation
The file ``sim_CM0_mult_VCD.csh`` and ``sim_CM0_no_mult_VCD.csh`` are used to launch the simulation with the generation of the activity annotation file and the ``sim_CM0_mult.csh`` and ``sim_CM0_no_mult.csh`` file are used to launch the simulation without generating this file. To launch the simulation with the script juste use the command :

``> tcsh script.csh``

The simulation generate one file : ``cortexm0.profile`` witch contain all the memory access done by the processor. Those file are analyzed using the Python code ``Memory Profiler.py`` in the ``analyze`` directory.

The performance is directly given in the console during the simulation.
# Synthesis
The synthesis is done with the design vision tool. To launch the synthesis juste use the following command :

``> dc_shell -f CortexMO.tcl`` or ``> dc_shell -f CortexM0_Multiplieur.tcl``

To modify the library used, change the ``target_library`` and ``TECHNO_DIR`` parameter in the ``config/synth.conf`` file.
