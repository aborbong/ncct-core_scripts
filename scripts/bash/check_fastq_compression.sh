#!/usr/bin/env bash
set -euo pipefail #Enable exiting the pipeline if any command fails

#Usage: check_fastq_compression <directory> <corrupted_output_file> <valid_output_file> <check_compression_command>


dir="$1" # Directory to check
corrupted_out="${2:-corrupted_fastq_files.txt}" # Default to corrupted_fastq_files.txt in the specified directory
valid_out="${3:-valid_fastq_files.txt}" # Default to valid_fastq_files.txt in the specified directory
check_compression="${4:-TRUE}" # Command to check compression integrity, default to TRUE

INVALID_COUNT=0 
VALID_COUNT=0

## Check if directory has files

shopt -s nullglob 
files=("$dir"/*)
if [ ${#files[@]} -eq 0 ]; then
    echo "No files found in the directory $dir"
    exit 1
fi

## Check if compression check is enabled

if [ "$check_compression" == "TRUE" ]; then
    echo "Starting gzip integrity check in directory: $dir"

## Iterate over files in the directory to check gzip integrity
    for i in "$dir"/*; do 
        if [[ "$i" == *.fastq.gz || "$i" == *.fq.gz ]]; then # Only check .fastq.gz or .fq.gz files
            if ! gzip -t "$i" 2>/dev/null; then # Test gzip integrity, suppress error output
            echo "Corrupted file detected: $i" >> "$corrupted_out" # Log corrupted file
            ((INVALID_COUNT++)) # Increment invalid count
           
        else
            echo "Valid file: $i" >> "$valid_out" # Log valid file
	        ((VALID_COUNT++)) # Increment valid count

        fi

    done

## Print summary report
    echo "FASTQ Compression Check Summary:" 
    echo "Valid compressed FASTQ files: $VALID_COUNT" 
    echo "Invalid compressed FASTQ files: $INVALID_COUNT" 
    echo "Detailed logs written to $corrupted_out and $valid_out"

    exit 0


else
    echo "Compression check is disabled. Starting data transfer to datamover"
    # Start data copy process
    for i in "$dir"/*; do 
        echo "Transferring file: $i"
        # Copy statement
        cp "$i" ~/datamover/data/incoming/
        echo "File transferred: $i" > log_transfer.txt
    done





            
    
