
# Check if the compressed FASTQ files in a directory are valid gzip files 
# Usage: check_fastq_compression <directory>

#1. Check if there are any .faastq.gz files in the specified directory 
for in "$1"/*.fastq.gz; do
    if [ ! -e "$i" ]; then
        echo "No .fastq.gz files found in the directory."
        exit 1
    fi
done
#2. For each .fastq.gz file, test if it is a valid gzip file using gzip -t 
for file in "$1"/*.fastq.gz; do
    if ! gzip -t "$file" >/dev/null 2>&1; then
        echo "Invalid gzip file: $file"
        echo "file" >> "$1/invalid_fastq_files.txt"
        INVALID_COUNT=$((INVALID_COUNT + 1))
    else
        echo "Valid gzip file: $file"
    fi
done
