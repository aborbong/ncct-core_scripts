#!/usr/bin/env bash
set -euo pipefail #Enable exiting the pipeline if any command fails

#Usage: ./concatenate_nanopore_files.sh </path/fo/fastq_pass> </path/to/fastq_faill> <output_folder> <mapping_file> [log_file]

INPUT_FOLDER_PASS="$1"
INPUT_FOLDER_FAIL="$2"
OUTPUT_FOLDER="$3"
MAPPING_FILE="$4"
LOG_FILE="$5"

mkdir -p $OUTPUT_FOLDER

# Function to log messages
log_message() {
    local message="$1"
    if [ -n "$LOG_FILE" ]; then
        # append to logfile and also print to stdout
        echo "$(date +"%Y-%m-%d %H:%M:%S") - $message" >> "$LOG_FILE"
        echo "$message"
    else
        echo "$message"
    fi
}

######--------------------------------
# Concatenate all pass.fastq.gz files
#####----------------------------------

# Print starting time
log_message "Process for pass.fastq.gz files started at $(date)"


# Loop to concatenate files and print processing time per sample
for i in $INPUT_FOLDER_PASS/barcode*/; do 

	#Extract barcode name
	barcode=$(basename "$i")
	
    # Print log message
    log_message "Processing barcode:$barcode"
	
	#Print start time
	start_time=$(date +%s)


	#Concatenate files & recomrpess in parallel
    # collect fastq.gz files safely
    files=( "$i"/*fastq.gz )
    if [ ${#files[@]} -eq 0 ] || [ ! -e "${files[0]}" ]; then
        log_message "No fastq.gz files found for $barcode, skipping" >> "$LOG_FILE"
    else
        # choose compressor: pigz if available, otherwise gzip
        if command -v pigz >/dev/null 2>&1; then
            COMPRESS_CMD="pigz -p 8 -c"
        else
            COMPRESS_CMD="gzip -c"
        fi
        # decompress all inputs and recompress into a single gzip member
        gzip -dc "${files[@]}" | eval $COMPRESS_CMD > "$OUTPUT_FOLDER/${barcode}_pass.fastq.gz"
    fi

	#Print finish time
	finish_time=$(date +%s)
	
	#Calculate duration of the concatenation
	total_duration=$((finish_time - start_time))

    # Print duration
    log_message "Finished processing barcode: $barcode in $total_duration seconds"

done

# Print finish time
log_message "Process for pass fastq files finished at $(date)"


######----------------------------
# Concatenate fail.fastq.gz files
#####-----------------------------


# Print starting time
log_message "Process for fail.fastq.gz files started at $(date)"


# Loop to concatenate files and print processing time per sample
for i in $INPUT_FOLDER_FAIL/barcode*/; do

        #Extract barcode name
        barcode=$(basename "$i")

    # Print log message
    log_message "Processing barcode:$barcode"

        #Print start time
        start_time=$(date +%s)

        # collect fastq.gz files safely for fail set
        files=( "$i"/*fastq.gz )
        if [ ${#files[@]} -eq 0 ] || [ ! -e "${files[0]}" ]; then
            log_message "No fastq.gz files found for $barcode (fail), skipping" >> "$LOG_FILE"
        else
            if command -v pigz >/dev/null 2>&1; then
                COMPRESS_CMD="pigz -p 8 -c"
            else
                COMPRESS_CMD="gzip -c"
            fi
            gzip -dc "${files[@]}" | eval $COMPRESS_CMD > "$OUTPUT_FOLDER/${barcode}_fail.fastq.gz"
        fi

    # Print finish time and duration
    finish_time=$(date +%s)
    total_duration=$((finish_time - start_time))
    log_message "Finished processing barcode: $barcode in $total_duration seconds"

done

# Print finish time
log_message "Process for fail fastq files finished at $(date)"


#-------------------------------------------
# Rename files according to mapping file 
#-------------------------------------------

mapfile="$MAPPING_FILE"
fastqdir="$OUTPUT_FOLDER"

# Rename all barcoded fastq files according to the mapping file
while IFS=$'\t' read -r barcode sample_name; do
    [[ -z "$barcode" || -z "$sample_name" || "$barcode" == "#"* ]] && continue

    for suffix in pass fail; do
        # Search fastqs with format barcode*_<suffix>.fastq.gz
        for old in "$fastqdir"/"${barcode}"*"_${suffix}.fastq.gz"; do
            [[ ! -e "$old" ]] && continue

            fname=$(basename -- "$old")
            # remove the leading barcode from the filename, keep the rest (including underscore and suffix)
            rest=${fname#"$barcode"}
            new="${fastqdir}/${sample_name}${rest}"

            echo "mv \"$old\" \"$new\""
            mv -f "$old" "$new"
        done
    done

done < "$mapfile"


log_message "Renaming process completed at $(date)"
log_message "All processes completed successfully!"
exit 0

