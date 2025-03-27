#!/bin/bash

# Base directory path
base_dir="/beegfs/DATA/TRAPUM/SCI-20230907-DP-01/20240927-0015/"

# Loop through each directory under the base directory
for dir in "$base_dir"/*/; do
    # Count the number of subdirectories inside this directory
    num_subdirs=$(find "$dir" -mindepth 1 -maxdepth 1 -type d | wc -l)
    
    # Extract the Jname from the apsuse.meta file using grep and awk
    Jname=$(grep -oP '"boresight": ".{10}' "$dir/apsuse.meta" | cut -c 15-25)

    # Print the Jname and the number of subdirectories
    echo "Jname: $Jname, Folders: $num_subdirs"
done

