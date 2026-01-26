#!/usr/bin/env bash
set -euo pipefail #Enable exiting the pipeline if any command fails

#Usage ./run_nanoplot.sh <INPUT_FOLDER> <OUTPUT_FOLDER> <LOG_FILE>
#Example: ./run_nanoplot.sh 251117_fastq_supAcc 251117_NanoPlot_fastq_supAcc_batch6

#Input arguments
INPUT_FOLDER="$1"
OUTPUT_FOLDER="$2"
LOG_FILE="$3"

INPUT_FOLDER="$1"

echo -e "sample\telapsed_seconds" > timelog.tsv

ls $INPUT_FOLDER/*.fastq.gz | parallel '
    sample={/.}
    start=$(date +%s)

    NanoPlot --fastq {} \
             --outdir 251117_NanoPlot_fastq_supAcc_batch6/$sample \
             --title $sample \
             -t 10 \
             --prefix ${sample}_

    end=$(date +%s)
    elapsed=$((end - start))

    echo -e "$sample\t$elapsed" >> timelog.tsv
'