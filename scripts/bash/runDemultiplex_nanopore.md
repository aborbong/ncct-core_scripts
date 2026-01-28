runDemultiplex_nanopore.sh
==========================

Purpose
-------
Collect per-barcode Nanopore demultiplexed FASTQ files from two folders (pass and fail), merge the per-barcode files into single compressed FASTQ files (one gzip member each), and rename the merged files to human-readable sample names using a mapping file.

Location
--------
scripts/bash/runDemultiplex_nanopore.sh

Requirements
------------
- gzip (standard)
- pigz (optional, for parallel compression)

Summary of behaviour
--------------------
- For each `barcode*/` subdirectory in the provided PASS and FAIL input folders, the script finds `*.fastq.gz` files.
- If files are found, it decompresses them in sequence (`gzip -dc file1.gz file2.gz ...`) and recompresses the concatenated FASTQ stream into a single gzip member using `pigz -c` (if available) or `gzip -c`.
- Output files are written to the provided OUTPUT_FOLDER with names like `<barcode>_pass.fastq.gz` and `<barcode>_fail.fastq.gz`.
- After concatenating pass/fail outputs, the script reads a tab-delimited mapping file (barcode <TAB> sample_name) and renames any matching "<barcode>*_pass.fastq.gz" and "<barcode>*_fail.fastq.gz" files to use the `sample_name` prefix while preserving the rest of the filename (any extra text and the `_pass`/`_fail` suffix).
- The script writes log messages using `log_message()` which appends timestamps to `LOG_FILE` if provided and also prints messages to stdout.

Usage
-----
```bash
./scripts/bash/runDemultiplex_nanopore.sh <INPUT_FOLDER_PASS> <INPUT_FOLDER_FAIL> <OUTPUT_FOLDER> <MAPPING_FILE> [LOG_FILE]
```

Positional arguments
- INPUT_FOLDER_PASS: directory containing per-barcode pass folders (e.g., /path/to/pass/barcode01/)
- INPUT_FOLDER_FAIL: directory containing per-barcode fail folders
- OUTPUT_FOLDER: directory where merged output fastq.gz files will be written (created if needed)
- MAPPING_FILE: tab-delimited file with two columns: barcode<TAB>sample_name
- LOG_FILE (optional): path to an appendable log file; when provided, the script will write timestamped lines there

Example
-------
From the repository root:
```bash
./scripts/bash/runDemultiplex_nanopore.sh test_data/nanopore_test/test_pass test_data/nanopore_test/test_fail test_data/nanopore_test/test_output test_data/nanopore_test/map_file_nanopore.tsv test.log
```

Notes and important details
---------------------------
- If you need maximum speed and you know downstream tools accept multi-member gz files, you could instead `cat file1.gz file2.gz > merged.gz` (NOT recommended unless you verified compatibility).
- Mapping file format: must be tab-delimited and not contain empty barcode/sample_name fields. Lines starting with `#` are ignored.
- Rename behavior: the script replaces the leading `barcode` in filenames with the mapped `sample_name` and keeps the rest of the filename (so `barcode01_extra_pass.fastq.gz` -> `SAMPLE_extra_pass.fastq.gz`). The rename uses `mv -f` (force overwrite) — if you prefer skipping existing targets, change the `mv` options accordingly.

Logging
-------
- If `LOG_FILE` is provided, `log_message()` appends timestamped messages to it and prints messages to stdout.
- Prefer absolute paths to avoid confusion about the current working directory.
