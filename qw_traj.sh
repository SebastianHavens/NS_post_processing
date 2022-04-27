#!/bin/bash

#files need: .energies
#            .traj 

#  argument 1 = characters before .traj
#  argument 2 = character after traj.   #this is the processor number first processor you want to analyse
#  argument 3 = last processor number you want to analyse
#  argument  4 = start temperature
#  argument  5 = Number of temperatures
#  argument  6 - difference between temperatures


if [ $# -lt 6 ]; then
    echo "Not all arguments provided"
    echo ""
    echo "  argument  1 = characters before .traj "
    echo "  argument  2 = character after traj.   #this is the processor number first processor you want to analyse"
    echo "  argument  3 = last processor number you want to analyse"
    echo "  argument  4 = start temperature"
    echo "  argument  5 = Number of temperatures"
    echo "  argument  6 = difference between temperatures"
    echo "  argument  7 = optional, -k value"
    exit 1
fi


mkdir qw46
mkdir rdf


if [ -z "$7" ]
  then
    ns_analyse "$1".energies -M "$4" -n "$5" -D "$6" > analyse.dat
  else
     ns_analyse "$1".energies -M "$4" -n "$5" -D "$6" -k "$7" > analyse.dat
fi


echo 'Energy:    Volume:    q4:      w4:    q6:    w6:  iteration:   Temp:  U:' > $1-$2-$3.qw46HV
for iter in $(seq "$2" "$3")
do	
	echo 'Processor number:'  $iter
	get_qw atfile_in=$1.traj.$iter.extxyz r_cut=3 l=4 calc_QWave=T print_QWxyz=T  > $1.traj.$iter.qw4
	get_qw atfile_in=$1.traj.$iter.extxyz r_cut=3 l=6 calc_QWave=T print_QWxyz=T > $1.traj.$iter.qw6
	
	#Extract data lines from QW output
	grep "[[:digit:]]\.[[:digit:]].*[[:digit:]]\.[[:digit:]]" $1.traj.$iter.qw4 > $1.qw4_temp
	grep "[[:digit:]]\.[[:digit:]].*[[:digit:]]\.[[:digit:]]" $1.traj.$iter.qw6 > $1.qw6_temp
	
	tail -n+12 $1.traj.$iter.qw4 | head -n-3 > $1.qw4_temp
	tail -n+12 $1.traj.$iter.qw6 | head -n-3 > $1.qw6_temp
	
	# grep the energies, ke,  volumes and iteration numbers from the traj files in neat columns and creat temporary files:
	grep -o "ns_energy=.[[:digit:]]*\.[[:digit:]]*" $1.traj.$iter.extxyz | sed "s/ns_energy=//g" >> $1.$iter.ener_temp
	grep -o "volume=.[[:digit:]]*\.[[:digit:]]*" $1.traj.$iter.extxyz | sed "s/volume=//g" >> $1.$iter.vol_temp
	grep -o "iter=.[[:digit:]]*" "$1".traj."$iter".extxyz | sed "s/iter=//g" >> $1.$iter.iter_temp
	grep -o "ns_KE=.[[:digit:]]*\.[[:digit:]]*" $1.traj.$iter.extxyz | sed "s/ns_KE=//g" >> $1.$iter.ke_temp
	
	./H_T_extrapolate.py analyse.dat "$1".$iter.ener_temp "$1".$iter.ke_temp
	
	#grep the energies, volume, Q and W data from the two files and create a summary result file, neatly arranging them by columns
	pr -m -t -s $1.$iter.ener_temp $1.$iter.vol_temp $1.qw4_temp $1.qw6_temp $1.$iter.iter_temp temp.temp U.temp| awk '{print $1,$2,$3,$4,$5,$6,$7,$8, $9 }' >> $1-$2-$3.qw46HV

	# remove the temporary files
	rm $1.qw4_temp
	rm $1.qw6_temp
	rm temp.temp
	rm U.temp


	rdf xyzfile=$1.traj.$iter.extxyz datafile=foo mask1=Cu mask2=Cu
	mv allrdf.out  allrdf.$iter.out
	
done
./weighted_rdf.py $1 $2 $3 $4 $5 $6

mv *.qw4 qw46
mv *.qw6 qw46
mv *.idx qw46
rm *_temp
rm foo
mv qw4_$1.traj.*.extxyz qw46
mv qw6_$1.traj.*.extxyz qw46
mv allrdf.*.out rdf
