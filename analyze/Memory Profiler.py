# Author : Damien Deprez, UCL (2019)

import re
import numpy as np

# fonction calulant le poids de Hamming d'un mot de 32 bits
def HammingWeight(word):
    hexweight = [0, 1, 1, 2, 1, 2, 2, 3, 1, 2, 2, 3, 2, 3, 3, 4]
    hex1 = (word & 0x0000000F)
    hex2 = (word & 0x000000F0) >> 4
    hex3 = (word & 0x00000F00) >> 8
    hex4 = (word & 0x0000F000) >> 12
    hex5 = (word & 0x000F0000) >> 16
    hex6 = (word & 0x00F00000) >> 20
    hex7 = (word & 0x0F000000) >> 24
    hex8 = (word & 0xF0000000) >> 28
    return hexweight[hex1] + hexweight[hex2] + hexweight[hex3] + hexweight[hex4] \
           + hexweight[hex5] + hexweight[hex6] + hexweight[hex7] + hexweight[hex8]


def Normalize(list):
    s = sum(list)
    return list if s == 0 else [float(i) / s for i in list]


def mean(list):
    m = 0
    item = 0
    total = 0
    for i in list:
        m += item * i
        total += i
        item += 1
    return m / total


def std(list):
    x2 = 0
    m = 0
    n = 0
    i = 0
    for item in list:
        x2 += item * i ** 2
        m += item * i
        n += item
        i += 1
    return np.sqrt(x2 / n - (m / n) ** 2)


imem_read_byte = [0] * 33
imem_read_half = [0] * 33
imem_read_word = [0] * 33

dmem_read_byte = [0] * 33
dmem_read_half = [0] * 33
dmem_read_word = [0] * 33

dmem_write_byte = [0] * 33
dmem_write_half = [0] * 33
dmem_write_word = [0] * 33

start =  256907700 # in ps
end = 5437233900  # in ps
elapsed = (end-start) * 1e-12 # in s

frequency = 80e6 # in Hz


file = open("D:\\UCL\\TFE\\ZeroRiscy-DMEM-O3.profile", "r")
for line in file:
    # utilisation du pattern matching pour récupérer les informations
    m = re.search("([ID][RW][BHW]) 0x([0-9a-fA-F]{1,8}) @ 0x([0-9a-fA-F]{1,8}) - \s* (\d+)", line)
    if m:
        type = m.group(1)
        data = int(m.group(2), 16)
        addr = int(m.group(3), 16)
        time = int(m.group(4))
        if time>= start and time <= end:
            if type == "IRB":
                data = data & 0x000000FF
                imem_read_byte[HammingWeight(data)] += 1
            elif type == "IRH":
                imem_read_half[HammingWeight(data & 0x0000FFFF)] += 1
            elif type == "IRW":
                imem_read_word[HammingWeight(data) - 1] += 1
            elif type == "DRB":
                data = data & 0x000000FF
                dmem_read_byte[HammingWeight(data)] += 1
            elif type == "DRH":
                dmem_read_half[HammingWeight(data & 0x0000FFFF)] += 1
            elif type == "DRW":
                dmem_read_word[HammingWeight(data)] += 1
            elif type == "DWB":
                data = data & 0x000000FF
                weight = HammingWeight(data)
                dmem_write_byte[weight] += 1
            elif type == "DWH":
                dmem_write_half[HammingWeight(data & 0x0000FFFF)] += 1
            elif type == "DWW":
                dmem_write_word[HammingWeight(data)] += 1
    else:
        print('line : "%s" not conform' % line.replace("\n", ""))


print("+-----------+-----------+-----------+------------+\n\
|           | IMEM READ | DMEM READ | DMEM WRITE |\n\
+-----------+-----------+-----------+------------+\n\
| BYTE      | %9d | %9d | %10d |\n\
| HALF-WORD | %9d | %9d | %10d |\n\
| WORD      | %9d | %9d | %10d |\n\
+-----------+-----------+-----------+------------+\n\
| TOTAL     | %9d | %9d | %10d |\n\
+-----------+-----------+-----------+------------+" %
      (sum(imem_read_byte), sum(dmem_read_byte), sum(dmem_write_byte),
       sum(imem_read_half), sum(dmem_read_half), sum(dmem_write_half),
       sum(imem_read_word), sum(dmem_read_word), sum(dmem_write_word),
       sum(imem_read_byte) + sum(imem_read_half) + sum(imem_read_word),
       sum(dmem_read_byte) + sum(dmem_read_half) + sum(dmem_read_word),
       sum(dmem_write_byte) + sum(dmem_write_half) + sum(dmem_write_word)))

print("\n")
print("Number of cycles : %d" % (elapsed * frequency))
