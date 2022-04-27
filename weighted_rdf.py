#!/usr/bin/env python3

import numpy as np
import math
import sys

prefix = sys.argv[1]
traj_start = int(sys.argv[2])
traj_end = int(sys.argv[3])
start_temp = float(sys.argv[4])
n_temp = int(sys.argv[5])
delta_temp = float(sys.argv[6])

n_walker_line = np.loadtxt(str(prefix) + '.energies', usecols=0)
n_walkers = n_walker_line[0]
print('N_walkers:' + str(n_walkers))
# kB           = 6.3336374823584e-6 # in Rydberg/K
kB = 8.617385e-5  # eV/K

# List of temperatures used in NS_analyse
T = [start_temp]
for x in range(1, n_temp):
    T.append(T[x - 1] + delta_temp)

# List of betas for each temp of NS_analyse
beta = []
for x in range(len(T)):
    beta.append(1.0 / (kB * T[x]))


bins = np.loadtxt(str('foo'), usecols=0)
sum_rdf = np.zeros((len(bins), n_temp))

# Looping through each trajectory file.

print('Calculating weighted RDF')
for traj in range(traj_start, traj_end):
    print('Trajectory file: ' + str(traj))
    iters = np.loadtxt(str(prefix + '.' + str(traj) + '.iter_temp'))

    E = np.loadtxt(str(prefix + '.' + str(traj) + '.ener_temp'))
    E_min = np.amin(E)
    print('E_min: ' + str(E_min))
    #E = E + abs(E_min) - 1
    E = E + abs(E_min)
    #print(E)

    rdf = np.loadtxt(str('allrdf.' + str(traj) + '.out'), usecols=1)
    rdf = np.reshape(rdf, (len(iters), len(bins)))

    z_array = np.zeros((len(iters), n_temp))
    #z_array = z_array - 5000000


    for x in range(len(iters)):

        log_w = (iters[x] * (math.log(n_walkers) - math.log(n_walkers + 1))) - math.log(n_walkers + 1)

        for y in range(n_temp):
            boltz_this = (-beta[y] * E[x])
            z_array[x, y] = boltz_this + log_w
            #print(z_array[x, y])
    for x in range(len(iters)):
        for y in range(n_temp):

            z_term = math.exp(z_array[x, y] - np.amax(z_array[:, y]))

            for k in range(len(bins)):
                sum_rdf[k, y] = sum_rdf[k, y] + rdf[x, k] * z_term
                print(rdf[x, k] * z_term)

sum_rdf = np.pad(sum_rdf, ((0, 0), (1, 0)), mode='constant', constant_values=0)
for x in range(len(bins)):
    sum_rdf[x, 0] = bins[x]
np.savetxt('weighted_rdf.out', sum_rdf[:, :],
           header='First column is bin radius, the following columns are each temperature used in ns_analyse, '
                  'for example if ns_analyse had -M 100 -n 10 -D 10 the second column would be temp 100, so you could '
                  'plot 1:2 for 100K, the next column would be 110K and could be plot with 1:3')
