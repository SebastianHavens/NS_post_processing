#!/usr/bin/env python3

import numpy as np
import sys
from scipy import interpolate

analyse_file = sys.argv[1]
energy_file  = sys.argv[2]
ke_file      = sys.argv[3]

try:
    T, U = np.loadtxt(str(analyse_file), comments='#', usecols=(0,3), unpack=True)
except:
    print('analysis file  does not exit')
    exit()

energy = np.loadtxt(str(energy_file))
ke     = np.loadtxt(str(ke_file))

U2=[]
for x in range(len(energy)):
#    U2.append(energy[x] - ke[x])
     U2.append(energy[x])


f = interpolate.interp1d(U,T, fill_value='extrapolate')


h_temp = open('temp.temp', 'w')
h_U = open('U.temp', 'w')
for x in range(len(U2) ) :
    h_temp.write(str(f(U2[x])) +  '\n')
    h_U.write(str(U2[x]) +'\n')
