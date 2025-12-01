#!/bin/bash

INPUT_FOLDER_PASS="/mnt/promdata/2510-Clavel-Batch6-WP1-ONT/2510-Clavel-Batch6-WP1-ONT/20251113_1414_1F_PBI55105_d9ba2691/fastq_pass/"
INPUT_FOLDER_FAIL="/mnt/promdata/2510-Clavel-Batch6-WP1-ONT/2510-Clavel-Batch6-WP1-ONT/20251113_1414_1F_PBI55105_d9ba2691/fastq_fail/"
OUTPUT_FOLDER="$PWD/251117_fastq_supAcc"


mkdir -p $OUTPUT_FOLDER

# Function to log messages
log_message() {
    local message="$1"
    if [ -n "$LOG_FILE" ]; then
        echo "$message" | tee -a "$LOG_FILE"
    else
        echo "$message"
    fi
}

######--------------------------------
# Concatenate all pass.fastq.gz files
#####----------------------------------

#Print starting time
log_message "Process for pass.fastq.gz files started at $(date)" 


# Loop to concatenate files and print processing time per sample
for i in $INPUT_FOLDER_PASS/barcode*/; do 

	#Extract barcode name
	barcode=$(basename "$i")
	
	#Print log message
	log_message "Processing barcode:$barcode"
	
	#Print start time
	start_time=$(date +%s)

	#Concatenate files
	zcat $i/*fastq.gz > "$OUTPUT_FOLDER/${barcode}_pass.fastq.gz"
	
	#Print finish time
	finish_time=$(date +%s)
	
	#Calculate duration of the concatenation
	total_duration=$((finish_time - start_time))

	#Print duration	
	log_message "Finished processing barcode: $barcode in $total_duration seconds"

done

#Print finish time
log_message "Process for pass files finished at $(date)"


######----------------------------
# Concatenate fail.fastq.gz files
#####-----------------------------


#Print starting time
log_message "Process for fail.fastq.gz files started at $(date)"


# Loop to concatenate files and print processing time per sample
for i in $INPUT_FOLDER_FAIL/barcode*/; do

        #Extract barcode name
        barcode=$(basename "$i")

        #Print log message
        log_message "Processing barcode:$barcode"

        #Print start time
        start_time=$(date +%s)

        #Concatenate files
        zcat $i/*fastq.gz > "$OUTPUT_FOLDER/${barcode}_fail.fastq.gz"

        #Print finish time
        finish_time=$(date +%s)

        #Calculate duration of the concatenation
        total_duration=$((finish_time - start_time))

        #Print duration
        log_message "Finished processing barcode: $barcode in $total_duration seconds"

done

#Print finish time
log_message "Process for fail files finished at $(date)" 



