#!/bin/sh

#files need: .energies
#            .traj 

#  argument 1 = charactrers before .traj #This will also be prefix of energies file
#  argument 2 = character after traj.   #this is the processer number first processor you want to analyse
#  argument 3 = last processor number you want to analyse

# ~/pymatnest/ns_analyse $1.energies -M 0.1 -n 500 -D 5 > analyse.dat

#Extract min. and max. energies from analysis file for later file truncation. "sort" orders the file according to column 4 (-nk4,4), then head and tail extracts first and last lines, then awk extracts only column 4.
U_min=$(sort -nk4,4 analyse.dat | head -n 1 | awk '{print $4}')
U_max=$(sort -nk4,4 analyse.dat | tail -n 1 | awk '{print $4}')

#Column headers
echo 'Temp:	Total energy:	Kinetic energy:	Volume:	q4:	w4:	q6:	w6:	iteration:' > $1-$2-$3.qw46HV

for iter in $(seq $2 $3)
do	
	echo 'Processor number:'  $iter
	get_qw atfile_in=$1.traj.$iter.extxyz r_cut=3 l=4 calc_QWave=T  > $1.traj.$iter.qw4
	get_qw atfile_in=$1.traj.$iter.extxyz r_cut=3 l=6 calc_QWave=T  > $1.traj.$iter.qw6
	
	#Extract data lines from QW output
	grep "[[:digit:]]\.[[:digit:]].*[[:digit:]]\.[[:digit:]]" $1.traj.$iter.qw4 > $1.qw4_temp
	grep "[[:digit:]]\.[[:digit:]].*[[:digit:]]\.[[:digit:]]" $1.traj.$iter.qw6 > $1.qw6_temp
	
	# grep the energies, ke,  volumes and iteration numbers from the traj files in neat columns and create temporary files:
	grep -o ns_energy=.[[:digit:]]*\.[[:digit:]]* $1.traj.$iter.extxyz | sed "s/ns_energy=//g" > $1.ener_temp
	grep -o ns_KE=.[[:digit:]]*\.[[:digit:]]* $1.traj.$iter.extxyz | sed "s/ns_KE=//g" > $1.ke_temp
	grep -o volume=.[[:digit:]]*\.[[:digit:]]* $1.traj.$iter.extxyz | sed "s/volume=//g" > $1.vol_temp
	grep -o iter=.[[:digit:]]*\.[[:digit:]]* $1.traj.$iter.extxyz | sed "s/iter=//g" > $1.iter_temp
	
	# Interpolate data to calculate temperature dependence
        H_T_extrapolate.py analyse.dat $1.ener_temp $1.ke_temp
	
	#Combine data files (using paste, where -d flag is used seperate columns with tabs), then use awk to extract lines that have energies within range given by analysis file
	paste -d "\t" $1.ener_temp $1.ke_temp $1.vol_temp $1.qw4_temp $1.qw6_temp $1.iter_temp | awk -v a="$U_min" '$1-$2 >= a' | awk -v a="$U_max" '$1-$2 <= a' > $1.all_temp

	#Add temperatures to data file
	paste -d "\t" temp.temp $1.all_temp >> $1-$2-$3.qw46HV

	#Seperate each data block with empty line
	echo "" >> $1-$2-$3.qw46HV	

	# remove the temporary files
	rm $1.ener_temp
	rm $1.vol_temp
	rm $1.qw4_temp
	rm $1.qw6_temp
	rm $1.iter_temp
	rm temp.temp
	rm $1.ke_temp
	rm $1.all_temp
done

mkdir qw46

mv *.qw4 qw46
mv *.qw6 qw46
mv *.idx qw46

