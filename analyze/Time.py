# Author : Damien Deprez, UCL (2019)

start_a = 82 # LSB
start_b = 208
start_c = 6
start_d = 0 # MSB

end_a = 82 # LSB
end_b = 208
end_c = 6
end_d = 0 # MSB

start_cycle = start_a + start_b*256 + start_c*65536 + start_d*256*256*256
end_cycle = end_a + end_b*256 + end_c*65536 + end_d*256*256*256

elapsed_cycle = end_cycle - start_cycle
print(elapsed_cycle)
