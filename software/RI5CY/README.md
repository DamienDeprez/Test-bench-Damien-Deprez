# Options
## Compiler
Change in the `Makefile`  the ``CC`` parameter with the location of your compiler
## Optimization
Change in the `Makefile`  the ``OPTIMIZATION`` parameter with the wanted optimization.

ex : ``OPTIMIZATION=-O3 -funroll-loops``

## Compressed Instruction
For using the compressed instruction, change in the ``Makefile`` the ``-march`` option in the ``CFLAGS`` parameter :

- with compressed instruction : ``-march=RV32IMCXpulpv2``
- without compressed instruction : ``-march=RV32IMXpulpv2``

# Building
For compiling the CoreMark for RI5CY run the following command :

```
> make clean
> make
```

## Output file
The output files are located in the ``output`` directory. Copy those files in the ``hardware\RI5CY\src\sw\`` directory. The name of the output files are :

- code-SUFFIX.hex
- data-SUFFIX.hex

The suffix can be changed by editing the ``NAME`` parameter in the ``Makefile``.
