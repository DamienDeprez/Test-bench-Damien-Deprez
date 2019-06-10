# Author : Damien Deprez, UCL (2019)
#

from elftools.elf.elffile import ELFFile
from sys import argv
import os

# Function : convert
#   convert the output file from the compiler to the memory content used by the
#   test bench.
def convert(file_name,suffix):
    elf = ELFFile(open(file_name,'rb'))
    instruction_memory = open('output/code-'+suffix+'.hex','w')
    data_memory = open('output/data-'+suffix+'.hex','w')
    dmem_addr=0x00100000;
    imem_addr=0x00000000;
    for section in elf.iter_sections():

        count = 0
        data = 0
        # Instruction memory section
        if section.name in ['.vectors', '.text', '.text.startup']:
            while imem_addr < section.header['sh_addr']:
                instruction_memory.write("%08X\n" % 0)
                imem_addr += 0x4
            for x in section.data():
                if count == 3:
                    data += x << (count * 8)
                    instruction_memory.write("%08X\n" % data)
                    instruction_memory.flush()
                    data = 0
                    count = 0
                    imem_addr += 0x4
                else:
                    data += x << (count * 8)
                    count += 1
        # Data memory section
        if section.name in ['.rodata', '.srodata.cst8', '.eh_frame', '.srodata.cst4', '.data', '.sdata']:
            while dmem_addr < section.header['sh_addr']:
                data_memory.write("%08X\n" % 0)
                dmem_addr += 0x4
            for x in section.data():
                if count == 3:
                    data += x << (count * 8)
                    data_memory.write("%08X\n" % data)
                    data_memory.flush()
                    data = 0
                    count = 0
                    dmem_addr += 0x4
                else:
                    data += x << (count * 8)
                    count += 1
    instruction_memory.close()
    data_memory.close()

if len(argv) != 3:
    print("Error type help for more information")
else:
    if argv[1] == 'help':
        print("Convert the elf file to the memory for RISC-V processor\n" \
               "use the command : python3 ELF2Mem.py File Suffix with File the input elf file and Prefix the Suffix for the output file\n")
    elif os.path.isfile(argv[1]):
        convert(argv[1], argv[2])
    else:
        print("File don't exist")
