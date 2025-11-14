#!/usr/bin/env bash
#Usage: check_fastq_compression <directory> <corrupted_output_file> <valid_output_file>

dir="$1"
corrupted_out="${2:-corrupted_fastq_files.txt}"
valid_out="${3:-valid_fastq_files.txt}"

    INVALID_COUNT=0 
    VALID_COUNT=0

for i in "$dir"/*; do 

    if [ ! -e "$i" ]; then
        echo "No gzipped files found in the directory."
        exit 1
        fi
    if [[ "$i" == *.fastq.gz || "$i" == *.fq.gz ]]; then
        if ! gzip -t "$i" 2>/dev/null; then
            echo "Corrupted file detected: $i" >> corrupted_fastq_files.txt
            INVALID_COUNT=(INVALID_COUNT + 1)
            
            else
            VALID_COUNT=(VALID_COUNT + 1)
            Vecho "Valid file: $i" >> valid_fastq_files.txt
    fi
    done
    echo "Valid compressed FASTQ files: $VALID_COUNT"
    echo "Invalid compressed FASTQ files: $INVALID_COUNT"
exit 0

            
    