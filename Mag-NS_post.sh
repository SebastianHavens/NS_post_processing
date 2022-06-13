#!/bin/bash

path=~/Programs/pymatnest/

source ./Mag-NS_post.input

gfortran $path/NS_post_processing/NS_weighted_rdf.f95 -o $path/NS_post_processing/NS_weighted_rdf.exe

ns_analyse "$prefix".energies -M "$start_temp" -n "$num_temp" -D "$delta_temp" -k "$boltz_const" > analyse.dat

echo 'Energy:    Volume:    Mnorm:	Mx:	My:	Mz:	E_Zeeman:	E_M:	iteration:   Temp:  U:' > $prefix.$proc_start-$proc_end.magHV

for iter in $(seq "$proc_start" "$proc_end")
do
        echo $prefix.traj.$iter.extxyz >> nw.dat
	echo 'Processor number:'  $iter

	# grep the energies, ke,  volumes and iteration numbers from the traj files in neat columns and creat temporary files:
	grep -o "ns_energy=.[[:digit:]]*\.[[:digit:]]*" "$prefix".traj."$iter".extxyz | sed "s/ns_energy=//g" >> "$prefix"."$iter".ener.temp
	grep -o "volume=.[[:digit:]]*\.[[:digit:]]*" "$prefix".traj."$iter".extxyz | sed "s/volume=//g" >> "$prefix"."$iter".vol.temp
	grep -o "iter=.[[:digit:]]*" "$prefix".traj."$iter".extxyz | sed "s/iter=//g" >> "$prefix"."$iter".iter.temp
	grep -o "ns_KE=.[[:digit:]]*\.[[:digit:]]*" "$prefix".traj."$iter".extxyz | sed "s/ns_KE=//g" >> "$prefix"."$iter".ke.temp
	grep -o "mag_norm=.[[:digit:]]*\.[[:digit:]]*" "$prefix".traj."$iter".extxyz | sed "s/^.*=//g" >> "$prefix"."$iter".mnorm.temp
	grep -o "mag_nvec=\".*\" mag" "$prefix".traj."$iter".extxyz | sed "s/^.*=\"\(.*\)\" mag/\1/g" >> "$prefix"."$iter".mvec.temp
	grep -o "BM_energy=.[[:digit:]]*\.[[:digit:]]*" "$prefix".traj."$iter".extxyz | sed "s/^.*=//g" >> "$prefix"."$iter".bme.temp
	grep -o "mag_energy=.[[:digit:]]*\.[[:digit:]]*" "$prefix".traj."$iter".extxyz | sed "s/^.*=//g" >> "$prefix"."$iter".mener.temp

#  mag_norm=0.9198221285483854 mag_nvec="-0.6575651741834401 -1.6004761777410135 -1.0493217558567367" mag_sd_angle=23.099907817309397 BM_energy=4.338253441669684e-06



	python $path/NS_post_processing/H_T_extrapolate.py analyse.dat "$prefix"."$iter".ener.temp "$prefix"."$iter".ke.temp
	
	wc -l *.temp

	#grep the energies, volume, Q and W data from the two files and create a summary result file, neatly arranging them by columns
	pr -m -t -s ${prefix}.${iter}.ener.temp $prefix.$iter.vol.temp "$prefix"."$iter".mnorm.temp "$prefix"."$iter".mvec.temp "$prefix"."$iter".bme.temp "$prefix"."$iter".mener.temp ${prefix}.${iter}.iter.temp temp.temp U.temp| awk '{print $prefix,$proc_start,$proc_end,$start_temp,$num_temp,$delta_temp,$7,$8, $9 }' >> $prefix.$proc_start-$proc_end.magHV

	wc -l $prefix.$proc_start-$proc_end.magHV

  # Collate files for weighted RDF
	cat "$prefix"."$iter".ener.temp >> collated_ener.temp
	cat "$prefix"."$iter".iter.temp >> collated_iter.temp

	# remove the temporary files
	rm temp.temp
	rm U.temp

done


# Merge column in each file to one file with 2 columns for weighted RDf.
paste collated_iter.temp collated_ener.temp > collated_iter_ener.temp


# Grabs the first word of the first line of the energies file - the number of walkers
n_walkers=$(cut -d' ' -f1 $prefix.energies | head -1)

# Calculate number of RDF bins

# Clean up
#rm *.temp

