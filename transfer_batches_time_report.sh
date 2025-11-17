#!/usr/bin/env bash

LOGFILE="time.log"

global_start=$(date +%s)
echo "==== SCRIPT START $(date) ====" | tee -a "$LOGFILE"

for file in VoolstraTransfer0*; do

    # Starting time
    start_ts=$(date +%s)
    echo "---- START $file at $(date) ----" | tee -a "$LOGFILE"

    # Transfer files
    while IFS= read -r line; do
        cp "$line" ~/datamover/data/incoming
    done < "$file"

    # End file
    end_ts=$(date +%s)
    duration=$((end_ts - start_ts))

    echo "---- END $file at $(date) ----" | tee -a "$LOGFILE"
    echo "Duration for $file: ${duration} seconds" | tee -a "$LOGFILE"
    echo "" | tee -a "$LOGFILE"

    # Sleep until it reaches the last file
    if [[ "$file" != "ClavelTransfer11" ]]; then
        echo "Sleeping 10 minutes..." | tee -a "$LOGFILE"
        sleep 600
    fi

done

global_end=$(date +%s)
global_dur=$((global_end - global_start))

echo "==== SCRIPT END $(date) ====" | tee -a "$LOGFILE"
echo "Total duration: ${global_dur} seconds" | tee -a "$LOGFILE"

