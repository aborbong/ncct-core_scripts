#!/usr/bin/env bash
#Usage: check_fastq_compression <directory> <corrupted_output_file> <valid_output_file>

dir="$1"
corrupted_out="${2:-corrupted_fastq_files.txt}"
valid_out="${3:-valid_fastq_files.txt}"

INVALID_COUNT=0 
VALID_COUNT=0

# Check if directory has files

shopt -s nullglob
files=("$dir"/*)
if [ ${#files[@]} -eq 0 ]; then
    echo "No files found in the directory $dir"
    exit 1
fi

for i in "$dir"/*; do 
    if [[ "$i" == *.fastq.gz || "$i" == *.fq.gz ]]; then
        if ! gzip -t "$i" 2>/dev/null; then
            echo "Corrupted file detected: $i" >> "$corrupted_out"
            ((INVALID_COUNT++))
           
        else
            echo "Valid file: $i" >> "$valid_out"
	     ((VALID_COUNT++))
            
	fi

    fi

done

    echo "Valid compressed FASTQ files: $VALID_COUNT"
    echo "Invalid compressed FASTQ files: $INVALID_COUNT"

    exit 0

            
    
