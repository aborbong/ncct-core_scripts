#!/usr/bin/env bash

set -euo pipefail

# Usage: ./run_nanoplot.sh <INPUT_FOLDER> <OUTPUT_FOLDER> <LOG_FILE> [THREADS]
# Example: ./run_nanoplot.sh 251117_fastq_supAcc 251117_NanoPlot_fastq_supAcc_batch6 nanoplot.log 10

# Input args
INPUT_FOLDER="${1:?Please provide INPUT_FOLDER}"
OUTPUT_FOLDER="${2:?Please provide OUTPUT_FOLDER}"
LOG_FILE="${3:?Please provide LOG_FILE}"
THREADS="${4:-10}"

mkdir -p "$OUTPUT_FOLDER"

#Activate nanoplot conda environment
conda activate nanoplot2

# Check dependencies
if ! command -v NanoPlot >/dev/null 2>&1; then
    echo "Error: NanoPlot is not installed or not in PATH." >&2
    exit 127
fi

if ! command -v parallel >/dev/null 2>&1; then
    echo "Error: GNU parallel is not installed or not in PATH." >&2
    echo "Install it (e.g. apt install parallel, brew install parallel) or run the script without parallel." >&2
    exit 127
fi

# Find input files safely
shopt -s nullglob
files=("$INPUT_FOLDER"/*.fastq.gz)
shopt -u nullglob

if [ ${#files[@]} -eq 0 ]; then
    echo "No .fastq.gz files found in '$INPUT_FOLDER'" >&2
    exit 1
fi

# Initialize temporary per-job logs and final log
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

echo -e "sample\telapsed_seconds" > "$LOG_FILE"

# Build parallel command: run NanoPlot per FASTQ and write per-sample timing to tmpdir
PAR_CMD='start=$(date +%s); NanoPlot --fastq {} --outdir "'"$OUTPUT_FOLDER"'/{/.}" --title {/.} -t 10 --prefix {/.}_; end=$(date +%s); echo -e "{/.}\t$((end-start))" > "'"$tmpdir"'/{/.}.log'

export OUTPUT_FOLDER tmpdir

# Run in parallel
parallel --halt now,fail=1 -j "$THREADS" "$PAR_CMD" ::: "${files[@]}"

# Combine per-sample logs into final log (preserve header)
for f in "$tmpdir"/*.log; do
    [ -e "$f" ] || continue
    tail -n +1 "$f" >> "$LOG_FILE"
done

echo "NanoPlot run completed. Results/logs written to '$OUTPUT_FOLDER' and '$LOG_FILE'"

