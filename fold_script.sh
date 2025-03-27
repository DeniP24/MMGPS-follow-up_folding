#!/bin/bash

#Options for epoch directory:
#TARGET_DIR="/beegfs/DATA/TRAPUM/SCI-20230907-DP-01/"
#mapfile -t subdirs < <(find "$TARGET_DIR" -mindepth 1 -maxdepth 1 -type d)

FILE="folders_to_fold.txt"
TEMP_FILE="folders_to_fold.tmp"

while IFS= read -r line; do
    subdirs+=("$line")
done < "$FILE"

echo $subdirs

while read -r subdir progress; do
    if [ "$progress" == "False" ]; then
        echo "Progress is False. Folding $subdir"
        Jname=$(grep -oP '"boresight": ".{10}' "$subdir/apsuse.meta" | cut -c 15-25)
        epoch=$(basename $subdir)
        epoch2=$(basename $epoch)
        echo "$Jname"_"$epoch"
#        mkdir "$Jname"_"$epoch"
        parfile="../parfiles/$Jname/$Jname.par"
        P0=$(grep -w "P0" "$parfile" | awk '{print $2}')
        DM=$(grep -w "DM" "$parfile" | awk '{print $2}')
        f0=$(echo "scale=10; 1 / $P0" | bc)
        mapfile -t beam_dirs < <(find "$subdir" -mindepth 1 -maxdepth 1 -type d)
        for beam in "${beam_dirs[@]}";do
            fil_files=$(ls $beam/*.fil)
            beam_name=$(basename $beam)
            echo "Folding $subdir. Beam $beam_name for pulsar $Jname for epoch $epoch" >> log.txt
            singularity exec -B /beegfs:/beegfs /homes/vishnu/singularity_images/pulsar_folder_latest.sif dspsr -E $parfile -A -O "$Jname"_"$epoch"/"$beam_name"_fold -L 60 -b 1024 $fil_files
            singularity exec -B /beegfs:/beegfs /homes/vishnu/singularity_images/pulsarx_latest.sif psrfold_fil -v -t 4 --template /beegfs/PROCESSING/USER_SCRATCH/dpillay/simgs/meerkat_fold.template --clfd 2.0 -z zdot -n 64 -b 64 --render --plotx --dm $DM --f0 $f0 -o         "$Jname"_"$epoch"/"$beam_name"_fold --cont -f $fil_files

        done
        echo "$subdir True" >> "$TEMP_FILE"
    else
        echo "$subdir $progress" >> "$TEMP_FILE"
    fi
done < "$FILE"

mv "$TEMP_FILE" "$FILE"

: <<'COMMENT'
for epoch_path in "${subdirs[@]}"; do
    mapfile -t pulsar_dirs < <(find "$epoch_path" -mindepth 1 -maxdepth 1 -type d)
    for pulsar_dir in "${pulsar_dirs[@]}"; do
        Jname=$(grep -oP '"boresight": ".{10}' "$pulsar_dir/apsuse.meta" | cut -c 15-25)
        epoch=$(basename $epoch_path)
        mkdir "$Jname"_"$epoch"
        parfile="../parfiles/$Jname/$Jname.par"
        P0=$(grep -w "P0" "$parfile" | awk '{print $2}')
        DM=$(grep -w "DM" "$parfile" | awk '{print $2}')
        f0=$(echo "scale=10; 1 / $P0" | bc)
        mapfile -t beam_dirs < <(find "$pulsar_dir" -mindepth 1 -maxdepth 1 -type d)
        echo $beam_dirs
        for beam in "${beam_dirs[@]}";do
            fil_files=$(ls $beam/*.fil)
            beam_name=$(basename $beam)
            echo "Folding beam $beam_name for pulsar $Jname for epoch $epoch"
            singularity exec -B /beegfs:/beegfs /homes/vishnu/singularity_images/pulsar_folder_latest.sif dspsr -E $parfile -A -O "$Jname"_"$epoch"/"$beam_name"_fold -L 60 -b 1024 $fil_files
            singularity exec -B /beegfs:/beegfs /homes/vishnu/singularity_images/pulsarx_latest.sif psrfold_fil -v -t 4 --template /beegfs/PROCESSING/USER_SCRATCH/dpillay/simgs/meerkat_fold.template --clfd 2.0 -z zdot -n 64 -b 64 --render --plotx --dm $DM --f0 $f0 -o "$Jname"_"$epoch"/"$beam_name"_fold --cont -f $fil_files
        done
    done
done
COMMENT