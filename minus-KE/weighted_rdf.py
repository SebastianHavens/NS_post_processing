#!/usr/bin/env python3

import numpy as np
import math
from mpmath import *
import sys

prefix     = sys.argv[1]
traj_start = int(sys.argv[2])
traj_end   = int(sys.argv[3])



n_point      = 1120
n_temp       = 100
start_temp   = 1000
delta_temp   = 10
#kB           = 6.3336374823584e-6 # in Rydberg/K
kB           = 8.617385e-5 #eV/K
n_walkers    = 500


T = [start_temp]
for x in range(1, n_temp) :
    T.append(T[x-1] + delta_temp)

beta = []
for x in range(len(T)) :
    beta.append(1.0 / (kB * T[x]))


bins = np.loadtxt(str('foo'), usecols=(0))
sum_rdf = np.zeros((len(bins),n_temp))

#Start trajectory loop here
for traj in range(traj_start, traj_end) :
    print('Trajectory file: ' +str(traj))
    iter = np.loadtxt(str(prefix + '.' + str(traj) +'.iter_temp'))
    
    E = np.loadtxt(str(prefix + '.' + str(traj) +'.ener_temp'))
    E_min = np.amin(E)
    E = E + abs(E_min ) - 1
    
    
    
    rdf = np.loadtxt(str('allrdf.' + str(traj) +'.out'), usecols=(1))
    rdf = np.reshape(rdf, (len(iter),len(bins)))
    
        
    
    
    z_array = np.zeros((len(iter),n_temp))
    z_array =  z_array - 5000000
    
    
    z_sum =[]
    for x in range(n_temp):
        z_sum.append(0)
        
    for x in range(len(iter)) :
        
        log_w = (iter[x]*((math.log(n_walkers)-math.log(n_walkers+1)))) - math.log(n_walkers+1) 
    
        for y in range(n_temp):
           
            boltz_this = (-beta[y] * E[x])
            z_array[x,y] = boltz_this +log_w   
    
            
            
    print('weight has been calculated')

    for x in range(len(iter)) :
        print('iteration: ' +str(x))
        for y in range(n_temp):
            
           # z_term = mpf(math.exp(z_array[x,y] - np.amax(z_array[:,y]))) #!!this could be right?
            z_term = math.exp(z_array[x,y] - np.amax(z_array[:,y])) #!!this could be right?
            #z_sum[y] = mpf(z_sum[y]) + mpf(z_term)
            z_sum[y] = z_sum[y] + z_term
            
            for k in range(len(bins)) :
           
                sum_rdf[k,y] = sum_rdf[k,y] + rdf[x,k] * z_term
            
h_weighted_rdf = open('weighted_rdf', 'w')
print('???????????????????????????????????????????????')
for x in len(bins):
    h_weighted_rdf.write(bins[x], sum_rdf[x,:])
