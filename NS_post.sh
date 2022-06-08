#!/bin/bash

source qw_traj.input

gfortran NS_weighted_rdf.f95 -o NS_weighted_rdf.exe

mkdir qw46
mkdir rdf



ns_analyse "$prefix".energies -M "$start_temp" -n "$num_temp" -D "$delta_temp" -k "$boltz_const" > analyse.dat



echo 'Energy:    Volume:    q4: :q     w4:    q6:    w6:  iteration:   Temp:  U:' > $prefix-$proc_start-$proc_end.qw46HV

for iter in $(seq "$proc_start" "$proc_end")
do
  echo $prefix.traj.$iter.extxyz >> nw.dat
	echo 'Processor number:'  $iter
	get_qw atfile_in=$prefix.traj.$iter.extxyz r_cut=3 l=4 calc_QWave=T print_QWxyz=T  > $prefix.traj.$iter.qw4
	get_qw atfile_in=$prefix.traj.$iter.extxyz r_cut=3 l=6 calc_QWave=T print_QWxyz=T > $prefix.traj.$iter.qw6
	
	#Extract data lines from QW output
	grep "[[:digit:]]\.[[:digit:]].*[[:digit:]]\.[[:digit:]]" $prefix.traj.$iter.qw4 > $prefix.qw4_temp
	grep "[[:digit:]]\.[[:digit:]].*[[:digit:]]\.[[:digit:]]" $prefix.traj.$iter.qw6 > $prefix.qw6_temp
	
	tail -n+12 $prefix.traj.$iter.qw4 | head -n-3 > $prefix.qw4_temp
	tail -n+12 $prefix.traj.$iter.qw6 | head -n-3 > $prefix.qw6_temp
	
	# grep the energies, ke,  volumes and iteration numbers from the traj files in neat columns and creat temporary files:
	grep -o "ns_energy=.[[:digit:]]*\.[[:digit:]]*" "$prefix".traj."$iter".extxyz | sed "s/ns_energy=//g" >> "$prefix"_"$iter"_ener_temp
	grep -o "volume=.[[:digit:]]*\.[[:digit:]]*" "$prefix".traj."$iter".extxyz | sed "s/volume=//g" >> "$prefix"."$iter".vol_temp
	grep -o "iter=.[[:digit:]]*" "$prefix".traj."$iter".extxyz | sed "s/iter=//g" >> "$prefix"_"$iter"_iter_temp
	grep -o "ns_KE=.[[:digit:]]*\.[[:digit:]]*" "$prefix".traj."$iter".extxyz | sed "s/ns_KE=//g" >> "$prefix"_"$iter"_ke_temp

	./H_T_extrapolate.py analyse.dat "$prefix"_"$iter"_ener_temp "$prefix"_"$iter"_ke_temp
	
	#grep the energies, volume, Q and W data from the two files and create a summary result file, neatly arranging them by columns
	pr -m -t -s $prefix_$iter_ener_temp $prefix.$iter.vol_temp $prefix.qw4_temp $prefix.qw6_temp $prefix_$iter_iter.temp temp.temp U.temp| awk '{print $prefix,$proc_start,$proc_end,$start_temp,$num_temp,$delta_temp,$7,$8, $9 }' >> $prefix-$proc_start-$proc_end.qw46HV



	rdf xyzfile=$prefix.traj.$iter.extxyz datafile=foo mask1="$atom_type" mask2="$atom_type" r_cut=$rdf_r_cut bin_width="$bin_width"

  # Collate files for weighted RDF
	cat allrdf.out >> collated_rdf.temp
	cat "$prefix"_"$iter"_ener_temp >> collated_ener.temp
	cat "$prefix"_"$iter"_iter_temp >> collated_iter.temp

	mv allrdf.out  allrdf.$iter.out

	# remove the temporary files
	rm $prefix.qw4_temp
	rm $prefix.qw6_temp
	rm temp.temp
	rm U.temp

done


# Merge column in each file to one file with 2 columns for weighted RDf.
paste collated_iter.temp collated_ener.temp > collated_iter_ener.temp


# Grabs the first word of the first line of the energies file - the number of walkers
n_walkers=$(cut -d' ' -f1 $prefix.energies | head -1)

# Calculate number of RDF bins
n_rdf_bins=$(echo "scale=0; $rdf_r_cut / $bin_width" | bc)

# Write file with parameters for weighted RDF:
echo "collated_rdf.temp collated_iter_ener.temp $n_walkers $n_rdf_bins $start_temp $num_temp $delta_temp $boltz_const " >> w_rdf_param.temp

echo "Calculating weighted RDF"
./NS_weighted_rdf.exe < w_rdf_param.temp >> w_rdf.out



# Clean up
mv *.qw4 qw46
mv *.qw6 qw46
mv *.idx qw46
rm *_temp
rm foo collated_rdf.temp collated_iter_ener.temp collated_iter.temp collated_ener.temp w_rdf_param.temp
mv qw4_$prefix.traj.*.extxyz qw46
mv qw6_$prefix.traj.*.extxyz qw46
mv allrdf.*.out rdf

