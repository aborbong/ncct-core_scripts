#!/usr/bin/env bash

# Usage: ./rename_fastqs.sh barcodes.tsv /path/to/fastqs

mapfile="$1"
fastqdir="$2"

while IFS=$'\t' read -r short full; do
    [[ -z "$short" || -z "$full" || "$short" == "#"* ]] && continue

    # Search fastqs with format: QGWQH551CU_S26_L001_R1_001.fastq.gz
    for old in "$fastqdir"/"${short}"_S*_L*_R*_*.fastq.gz; do

        [[ ! -e "$old" ]] && continue

        # Extract the suffix after Qbic barcode_
        suffix="${old#${fastqdir}/${short}_}"

        # Create the new name
        new="${fastqdir}/${full}_${suffix}"

	#Rename file
        echo "mv \"$old\" \"$new\""
        mv "$old" "$new"

    done

done < "$mapfile"
