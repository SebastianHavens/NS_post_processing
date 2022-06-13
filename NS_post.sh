#!/bin/bash

source ./NS_post.input


# Finds fortran files and compiles them if they haven't already been compiled.
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]:-$0}"; )" &> /dev/null && pwd 2> /dev/null; )";
gfortran "$SCRIPT_DIR"/NS_weighted_rdf.f95 -o "$SCRIPT_DIR"/NS_weighted_rdf.exe

mkdir qw46
mkdir rdf



ns_analyse "$prefix".energies -M "$start_temp" -n "$num_temp" -D "$delta_temp" -k "$boltz_const" > analyse.dat



echo 'Energy:    Volume:    q4: :q     w4:    q6:    w6:  iteration:   Temp:  U:' > "$prefix".qw46HV

for iter in $(seq "$proc_start" "$proc_end")
do
	echo 'Processor number:'  "$iter"
	get_qw atfile_in=$prefix.traj."$iter".extxyz r_cut="$qw_r_cut" l=4 calc_QWave=T print_QWxyz=T  > "$prefix"_"$iter".qw4
	get_qw atfile_in=$prefix.traj."$iter".extxyz r_cut="$qw_r_cut" l=6 calc_QWave=T print_QWxyz=T > "$prefix"_"$iter".qw6
	
	#Extract data lines from QW output
	grep "[[:digit:]]\.[[:digit:]].*[[:digit:]]\.[[:digit:]]" "$prefix"_"$iter".qw4 > "$prefix"_"$iter"_qw4.temp
	grep "[[:digit:]]\.[[:digit:]].*[[:digit:]]\.[[:digit:]]" "$prefix"_"$iter".qw6 > "$prefix"_"$iter"_qw6.temp
	
	tail -n+12 "$prefix"_"$iter".qw4 | head -n-3 > "$prefix"_qw4.temp
	tail -n+12 "$prefix"_"$iter".qw6 | head -n-3 > "$prefix"_qw6.temp
	
	# grep the energies, ke,  volumes and iteration numbers from the traj files in neat columns and creat temporary files:
	grep -o "ns_energy=.[[:digit:]]*\.[[:digit:]]*" "$prefix".traj."$iter".extxyz | sed "s/ns_energy=//g" >> "$prefix"_"$iter"_ener.temp
	grep -o "volume=.[[:digit:]]*\.[[:digit:]]*" "$prefix".traj."$iter".extxyz | sed "s/volume=//g" >> "$prefix"_"$iter"_vol.temp
	grep -o "iter=.[[:digit:]]*" "$prefix".traj."$iter".extxyz | sed "s/iter=//g" >> "$prefix"_"$iter"_iter.temp
	grep -o "ns_KE=.[[:digit:]]*\.[[:digit:]]*" "$prefix".traj."$iter".extxyz | sed "s/ns_KE=//g" >> "$prefix"_"$iter"_ke.temp

	H_T_extrapolate.py analyse.dat "$prefix"_"$iter"_ener.temp "$prefix"_"$iter"_ke.temp
	
	#grep the energies, volume, Q and W data from the two files and create a summary result file, neatly arranging them by columns
	pr -m -t -s "$prefix"_"$iter"_ener.temp "$prefix"_"$iter"_vol.temp "$prefix"_"$iter"_qw4.temp "$prefix"_"$iter"_qw6.temp "$prefix"_"$iter"_iter.temp temp.temp U.temp| awk '{print $prefix,$proc_start,$proc_end,$start_temp,$num_temp,$delta_temp,$7,$8, $9 }' >> "$prefix".qw46HV



	rdf xyzfile="$prefix".traj."$iter".extxyz datafile=foo.temp mask1="$atom_type" mask2="$atom_type" r_cut="$rdf_r_cut" bin_width="$bin_width" >> NS_post.out

  # Collate files for weighted RDF
	cat allrdf.out >> collated_rdf.temp
	cat "$prefix"_"$iter"_ener.temp >> collated_ener.temp
	cat "$prefix"_"$iter"_iter.temp >> collated_iter.temp
  mv allrdf.out  allrdf."$iter".out

	# remove the temporary files produced by H_T_extrapolate.py
	rm temp.temp
	rm U.temp

done


# Merge column in each file to one file with 2 columns for weighted RDf.
paste collated_iter.temp collated_ener.temp > collated_iter_ener.temp


# Grabs the first word of the first line of the energies file - the number of walkers
n_walkers=$(cut -d' ' -f1 "$prefix".energies | head -1)

# Calculate number of RDF bins
n_rdf_bins=$(echo "scale=0; $rdf_r_cut / $bin_width" | bc)

# Write file with parameters for weighted RDF:
echo "collated_rdf.temp collated_iter_ener.temp $n_walkers $n_rdf_bins $start_temp $num_temp $delta_temp $boltz_const " >> w_rdf_param.temp

echo "Calculating weighted RDF"
rm w_rdf.out
NS_weighted_rdf.exe < w_rdf_param.temp >> w_rdf.out



# Clean up
mv *.qw4 qw46
mv *.qw6 qw46
mv *.idx qw46
mv qw4_$prefix.traj.*.extxyz qw46
mv qw6_$prefix.traj.*.extxyz qw46
mv allrdf.*.out rdf
rm *.temp

