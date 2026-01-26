#!/usr/bin/env bash

#Usage ./run_nanoplot.sh <INPUT_FOLDER> <OUTPUT_FOLDER> <LOG_FILE>
#Example: ./run_nanoplot.sh 251117_fastq_supAcc 251117_NanoPlot_fastq_supAcc_batch6

#Input arguments
INPUT_FOLDER="$1"
OUTPUT_FOLDER="$2"
LOG_FILE="$3"

#Create output folder if it does not exist
mkdir -p $OUTPUT_FOLDER

#Initialize log file
echo -e "sample\telapsed_seconds" > $LOG_FILE

#Run NanoPlot in parallel for all fastq.gz files in the input folder
ls $INPUT_FOLDER/*.fastq.gz | parallel '
    sample= $(basename {} .fastq.gz)
    start=$(date +%s)

    NanoPlot --fastq {} \
             --outdir $OUTPUT_FOLDER/${sample} \
             --title ${sample} \
             -t 10 \
             --prefix ${sample}_

    end=$(date +%s)
    elapsed=$((end - start))

    echo -e "$sample\t$elapsed" >> $LOG_FILE
    mv $LOG_FILE $OUTPUT_FOLDER/$LOG_FILE

'
