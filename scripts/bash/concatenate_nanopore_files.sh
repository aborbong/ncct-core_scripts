#!/bin/bash

#Usage: ./concatenate_nanopore_files.sh </path/fo/fastq_pass> </path/to/fastq_faill> <output_folder>

INPUT_FOLDER_PASS="$1"
INPUT_FOLDER_FAIL="$2"
OUTPUT_FOLDER="$3"


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

	#Concatenate files & recomrpess in parallel
	zcat $i/*fastq.gz | pigz -p 8 -c > "$OUTPUT_FOLDER/${barcode}_pass.fastq.gz"
	
	#Print finish time
	finish_time=$(date +%s)
	
	#Calculate duration of the concatenation
	total_duration=$((finish_time - start_time))

	#Print duration	
	log_message "Finished processing barcode: $barcode in $total_duration seconds" 

done

#Print finish time
log_message "Process for pass fastq files finished at $(date)"


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
        zcat $i/*fastq.gz | pigz -p 8 -c > "$OUTPUT_FOLDER/${barcode}_fail.fastq.gz"

        #Print finish time
        finish_time=$(date +%s)

        #Calculate duration of the concatenation
        total_duration=$((finish_time - start_time))

        #Print duration
        log_message "Finished processing barcode: $barcode in $total_duration seconds"

done

#Print finish time
log_message "Process for fail fastq files finished at $(date)" 



