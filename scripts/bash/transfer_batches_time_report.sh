#!/usr/bin/env bash
set -euo pipefail

# Script to transfer files in batches with time logging and pauses between batches
# Usage: transfer_batches_time_report.sh [-l logfile] [-n n_batches] [-d]
#
# Options:
#   -l <logfile>    Path to logfile (required unless provided positionally)
#   -n <n_batches>  Number of lines per batch (required unless provided positionally)
#   -d              Dry-run: print actions instead of executing them
#   -h              Show this help

DRYRUN=0
LOGFILE=""
N_BATCHES=""

# Parse short options with getopts
while getopts ":l:n:dh" opt; do
    case "$opt" in
        l) LOGFILE="$OPTARG" ;;
        n) N_BATCHES="$OPTARG" ;;
        d) DRYRUN=1 ;;
        h) echo "Usage: $0 [-l logfile] [-n n_batches] [-d]"; exit 0 ;;
        :) echo "Option -$OPTARG requires an argument." >&2; exit 2 ;;
        \?) echo "Unknown option: -$OPTARG" >&2; exit 2 ;;
    esac
done
shift $((OPTIND -1))

# Positional fallback: if flags not provided, accept positional args
if [[ -z "$LOGFILE" ]]; then
    LOGFILE="${1:-}"
    # shift if we consumed a positional arg
    [[ -n "$LOGFILE" ]] && shift || true
fi
if [[ -z "$N_BATCHES" ]]; then
    N_BATCHES="${1:-}"
fi

if [[ -z "$LOGFILE" || -z "$N_BATCHES" ]]; then
    echo "Usage: $0 [-l logfile] [-n n_batches] [-d]" >&2
    exit 2
fi

# Ensure logfile directory exists (append mode will create file)
mkdir -p "$(dirname "$LOGFILE")"

# record global start time
global_start=$(date +%s)
echo "==== SCRIPT START $(date) ====" | tee -a "$LOGFILE"

# Create temporary directories
mkdir -p tmp tmp_transfer

# Build list of files 
shopt -s nullglob
files=( *.fastq.gz )
if [[ ${#files[@]} -eq 0 ]]; then
    echo "No .fastq.gz files found in current directory." | tee -a "$LOGFILE"
    : > tmp/all_files.txt
else
    printf '%s\n' "${files[@]}" > tmp_transfer/all_files.txt
fi

# Split files into batches in a portable way (avoid GNU-only flags)
# This will create files with suffixes like tmp/FilesTransfer_aa, tmp/FilesTransfer_ab, ...
split -l "$N_BATCHES" tmp_transfer/all_files.txt tmp/FilesTransfer_ || true

# Collect batch files using a glob into a bash array (portable)
shopt -s nullglob
batch_files=(tmp/FilesTransfer_*)
if [[ ${#batch_files[@]} -eq 0 ]]; then
    # create a single empty batch file to iterate over
    : > tmp/FilesTransfer_0
    batch_files=(tmp/FilesTransfer_0)
fi

# Determine last batch in a bash-3-compatible way
last_index=$((${#batch_files[@]} - 1))
last_batch="${batch_files[$last_index]}"

for file in tmp/FilesTransfer_*; do

    # Starting time
    start_ts=$(date +%s)
    echo "---- START $file at $(date) ----" | tee -a "$LOGFILE"

    # Transfer files (or print actions in dryrun)
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip empty lines
        [[ -z "$line" ]] && continue

        if [[ $DRYRUN -eq 1 ]]; then
            echo "DRYRUN: would copy '$line' to ~/datamover/data/incoming" | tee -a "$LOGFILE"
        else
            echo "Copying '$line' -> ~/datamover/data/incoming" | tee -a "$LOGFILE"
            cp "$line" ~/datamover/data/incoming
        fi
    done < "$file"

    # End file
    end_ts=$(date +%s)
    duration=$((end_ts - start_ts))

    echo "---- END $file at $(date) ----" | tee -a "$LOGFILE"
    echo "Duration for $file: ${duration} seconds" | tee -a "$LOGFILE"
    echo "" | tee -a "$LOGFILE"

    # Sleep between batches except after the last one
    if [[ "$file" != "$last_batch" ]]; then
        if [[ $DRYRUN -eq 1 ]]; then
            echo "DRYRUN: would sleep 10 minutes between batches" | tee -a "$LOGFILE"
        else
            echo "Sleeping 10 minutes..." | tee -a "$LOGFILE"
            sleep 600
        fi
    fi

done

global_end=$(date +%s)
global_dur=$((global_end - global_start))

echo "==== SCRIPT END $(date) ====" | tee -a "$LOGFILE"
echo "Total duration: ${global_dur} seconds" | tee -a "$LOGFILE"

