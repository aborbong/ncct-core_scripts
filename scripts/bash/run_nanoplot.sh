#!/usr/bin/env bash

INPUT_FOLDER="251117_fastq_supAcc/"

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
