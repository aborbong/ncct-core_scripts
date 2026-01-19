#!/usr/bin/env bash
set -euo pipefail #Enable exiting the pipeline if any command fails

#Usage: check_fastq_compression.sh [--skip-check|-s] [--parallel|-p <num>] <directory> <corrupted_output_file> <valid_output_file>
#
# Options:
#   --skip-check, -s   Skip the gzip compression checks and report success (useful for debugging or force-transfer)
#   --parallel, -p   Number of parallel processes to use (default: 1)

# Default options
SKIP_CHECK=0
PARALLEL=1

# Parse options (support -s/--skip-check and -p/--parallel)
while [[ "${1:-}" == -* ]]; do
    case "$1" in
        -s|--skip-check)
            SKIP_CHECK=1; shift ;;
        -p|--parallel)
            shift
            PARALLEL="${1:-}"
            if [[ -z "$PARALLEL" ]]; then
                echo "Option -p|--parallel requires a numeric argument" >&2
                exit 2
            fi
            shift ;;
        -h|--help)
            echo "Usage: $0 [--skip-check|-s] [--parallel|-p <num>] <directory> [corrupted_output_file] [valid_output_file]"; exit 0 ;;
        *)
            break ;;
    esac
done

# Read positional args with safe defaults
dir="${1:-}"
corrupted_out="${2:-corrupted_fastq_files.txt}"
valid_out="${3:-valid_fastq_files.txt}"

## Validate arguments
if [[ -z "$dir" ]]; then #check if dir is empty
    echo "Usage: $0 [--skip-check|-s] <directory> [corrupted_output_file] [valid_output_file]" >&2
    exit 2
fi

if [[ ! -d "$dir" ]]; then #check if dir exists and is a directory
    echo "Error: directory '$dir' does not exist or is not a directory." >&2
    exit 2
fi

## Build list of FASTQ files (gzipped)
shopt -s nullglob
files=("$dir"/*.fastq.gz "$dir"/*.fq.gz)
if [[ ${#files[@]} -eq 0 ]]; then
    echo "No .fastq.gz or .fq.gz files found in the directory $dir" | tee -a "$valid_out"
    exit 1
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
else    
    echo "Starting compression checks for directory: $dir"

    # Truncate/create output files so we don't append to previous runs
    : > "$corrupted_out"
    : > "$valid_out"

    ## Initialize counters
    INVALID_COUNT=0
    VALID_COUNT=0

    # Validate PARALLEL is a positive integer
    if ! [[ "$PARALLEL" =~ ^[0-9]+$ ]]; then
        echo "Invalid --parallel value: $PARALLEL (must be a positive integer)" >&2
        exit 2
    fi

    # If PARALLEL <= 1 do serial, otherwise parallel
    if (( PARALLEL <= 1 )); then
        for i in "${files[@]}"; do
            if ! gzip -t "$i" 2>/dev/null; then
                echo "Corrupted file detected: $i" >> "$corrupted_out"
                ((INVALID_COUNT++))
            else
                echo "Valid file: $i" >> "$valid_out"
                ((VALID_COUNT++))
            fi
        done
    else
        # using pigz for parallel gzip testing
        results=$(mktemp)
    printf '%s\0' "${files[@]}"  | xargs -0 -n1 -P "$PARALLEL" -I{} sh -c 'pigz -t "{}" >/dev/null 2>&1 && echo VALID "{}" || echo CORRUPT "{}"' > "$results"
        while IFS= read -r line || [[ -n "$line" ]]; do
            status=$(echo "$line" | awk '{print $1}')
            filepath=$(echo "$line" | cut -d' ' -f2-)
            
            if [[ "$status" == "CORRUPT" ]]; then
                echo "Corrupted file detected: $filepath" >> "$corrupted_out"
                ((INVALID_COUNT++))
            else
                echo "Valid file: $filepath" >> "$valid_out"
                ((VALID_COUNT++))
            fi
        done < "$results"
        rm -f "$results"
    fi


echo "Valid compressed FASTQ files: $VALID_COUNT"
echo "Invalid compressed FASTQ files: $INVALID_COUNT"

# Start data transfer only if no corrupted files were found
if [[ $INVALID_COUNT -gt 0 ]]; then
    echo "Corrupted files detected. Data transfer aborted"
    exit 1
else
    echo "Starting data transfer to datamover"

    # Start data copy process
    for i in "$dir"/*; do 
        echo "Transferring file: $i"
       # Copy statement
       if [[ $i == *.fastq.gz || $i == *.fq.gz ]]; then
           cp "$i" ~/datamover/data/incoming/
           echo "File transferred: $i" >> transferred_files.log
           transferred_files=$(wc -l < transferred_files.log)
           #echo "Total files transferred: $transferred_files"
       fi   
    done
    echo "Total files transferred: $transferred_files"
    exit 0
fi
    exit 0 
fi 
    