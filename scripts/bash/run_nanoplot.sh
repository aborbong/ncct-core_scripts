#!/usr/bin/env bash

#Usage ./run_nanoplot.sh <INPUT_FOLDER> <OUTPUT_FOLDER>
#Example: ./run_nanoplot.sh 251117_fastq_supAcc 251117_NanoPlot_fastq_supAcc

INPUT_FOLDER="$1"
OUTPUT_FOLDER="$2"

mkdir -p "$OUTPUT_FOLDER"

echo -e "sample\telapsed_seconds" > timelog.tsv | tee -a timelog.tsv >/dev/null

export OUTPUT_FOLDER

shopt -s nullglob
files=("$INPUT_FOLDER"/*.fastq.gz)


printf '%s\n' "${files[@]}" | parallel --env OUTPUT_FOLDER '
    sample={/.}
    start=$(date +%s)

    NanoPlot --fastq {} \
             --outdir "$OUTPUT_FOLDER"/$sample \
             --title $sample \
             -t 10 \
             --prefix ${sample}_

    end=$(date +%s)
    elapsed=$((end - start))

    echo -e "$sample\t$elapsed" 
' >> timelog.tsv
