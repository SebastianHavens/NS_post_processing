#!/usr/bin/env python3

import numpy as np
import sys


analyse_file = 'pf'
energy_file  = sys.argv[1]
ke_file      = sys.argv[2]

try:
    T, U = np.loadtxt(str(analyse_file), comments='#', usecols=(0,3), unpack=True)
except:
    print('pf does not exit')
    exit()
energy = np.loadtxt(str(energy_file))
ke     = np.loadtxt(str(ke_file))

deriv=0
for f in range(len(U) -1 ) :
    deriv += (T[f+1] - T[f]) / (U[f+1] - U[f])

deriv = deriv / (len(U) -1)
const = abs(U[1] * deriv)
h_temp = open('temp.temp', 'w')
for f in range(len(energy) ) :
    h_temp.write(str(( ( (energy[f] - ke[f]) * deriv) + const )) + '\n')
