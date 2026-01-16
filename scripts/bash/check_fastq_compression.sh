#!/usr/bin/env bash
set -euo pipefail #Enable exiting the pipeline if any command fails

#Usage: check_fastq_compression.sh [--skip-check|-s] <directory> <corrupted_output_file> <valid_output_file>
#
# Options:
#   --skip-check, -s   Skip the gzip compression checks and report success (useful for debugging or force-transfer)

## Optional flag to skip the compression check
SKIP_CHECK=0
if [[ "${1:-}" == "--skip-check" || "${1:-}" == "-s" ]]; then
    SKIP_CHECK=1
    shift
fi

# Read args with safe defaults
dir="${1:-}"
corrupted_out="${2:-corrupted_fastq_files.txt}"
valid_out="${3:-valid_fastq_files.txt}"

## Validate arguments
if [[ -z "$dir" ]]; then #check if dir is empty
    echo "Usage: $0 [--skip-check|-s] <directory> [corrupted_output_file] [valid_output_file]" >&2
    exit 2
fi

if [[ ! -d "$dir" ]]; then
    echo "Error: directory '$dir' does not exist or is not a directory." >&2
    exit 2
fi

## If  SKIP_CHECK is set, skip the compression checks and start the data transfer
if [[ $SKIP_CHECK -eq 1 ]]; then
    echo "Skipping compression checks for directory: $dir"
    echo "Starting data transfer to datamover"
    
    # Start data copy process
    for i in "$dir"/*; do 
        echo "Transferring file: $i"
       # Copy statement
       if [[ $i == *.fastq.gz || $i == *.fq.gz ]]; then
           cp "$i" ~/datamover/data/incoming/
           echo "File transferred: $i" >> transferred_files.log
       fi   
    done
    exit 0
fi

# Truncate/create output files so we don't append to previous runs
: > "$corrupted_out"
: > "$valid_out"

## Initialize counters
INVALID_COUNT=0
VALID_COUNT=0

## Check if directory has files
shopt -s nocaseglob 
files=("$dir"/*)
if [[ ${#files[@]} -eq 0 ]]; then
    echo "No files found in the directory $dir"
    exit 1
fi

for i in "$dir"/*; do
    # Match common FASTQ gzip extensions (case-insensitive).
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

# Start data transfer only if no corrupted files were found
if [[ $INVALID_COUNT -gt 0 ]]; then
    echo "Corrupted files detected. Data transfer aborted"
else
    echo "Starting data transfer to datamover"

    # Start data copy process
    for i in "$dir"/*; do 
        echo "Transferring file: $i"
       # Copy statement
       if [[ $i == *.fastq.gz || $i == *.fq.gz ]]; then
           cp "$i" ~/datamover/data/incoming/
           echo "File transferred: $i" >> transferred_files.log
       fi   
    done
    exit 0
fi

exit 0






