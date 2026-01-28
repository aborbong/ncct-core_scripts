Bash scripts for NCCT core workflows
==================================

This directory contains small helper bash scripts used in NCCT data processing workflows (concatenation/renaming of demultiplexed FASTQ files, basic checks and running NanoPlot). This README describes each script, required inputs, example usage and troubleshooting tips.

Contents
--------
- `concatenate_nanopore_files.sh` — concatenate per-barcode FASTQ.gz files (pass/fail), recompress into single gzip members and rename according to a mapping file.
- `run_nanoplot.sh` — run NanoPlot on a set of compressed FASTQ files (parallelized with GNU `parallel`).
- `check_fastq_compression.sh` — (utility) checks compression of FASTQ files (report valid / corrupted files).
- `rename_fastq.sh` — (utility) rename FASTQ files according to a mapping or pattern.
- `transfer_batches_time_report.sh` — produce a time report for transfer batches.

Notes: some scripts are expected to be maintained and extended in the repo. If you plan to run them on your system, read the details for the most important scripts below.

concatenate_nanopore_files.sh
-----------------------------
Purpose
:  Collects per-barcode fastq.gz files under two input folders (pass and fail), decompresses all matched gzip members, recompresses into a single gzip file per barcode (one member), and then renames files according to a mapping file (barcode -> sample name).

Key behaviour
:  - Safely checks that globs matched files before running decompression to avoid "can't stat" errors.
  - Uses `gzip -dc` to stream-decompress all inputs and `pigz -c` (if available) or `gzip -c` to recompress into one gzip member.
  - Supports both `_pass` and `_fail` output suffixes and will rename files to the sample name while preserving the suffix and any extra filename fragments.
  - Writes logs via `log_message()` (timestamps appended when `LOG_FILE` is provided).

Usage
:  ./concatenate_nanopore_files.sh <INPUT_FOLDER_PASS> <INPUT_FOLDER_FAIL> <OUTPUT_FOLDER> <MAPPING_FILE> [LOG_FILE]

Example
:  ./concatenate_nanopore_files.sh /data/fastq_pass /data/fastq_fail /data/merged map_file.tsv process.log

Mapping file format
: Tab-delimited, two columns: barcode <TAB> sample_name
  Lines starting with `#` or empty fields are skipped.

Notes & recommendations
:  - Install `pigz` if you want multithreaded compression (`brew install pigz` or `sudo apt install pigz`).
  - The script recompresses into a single gzip member which is more portable to downstream tools than simply concatenating `.gz` members with `cat`.
  - The script uses bash arrays and `gzip -dc`, so run it with bash (shebang uses `/usr/bin/env bash`).
  - If you need faster behavior and are certain your downstream tools accept multi-member gz, you can replace the recompression with `cat ${files[@]} > out.gz` but be aware of portability caveats.
  - The script now appends timestamps to the log file and avoids accidental overwrites.


run_nanoplot.sh
---------------
Purpose
:  Run NanoPlot for each compressed FASTQ file in the input folder in parallel and collect per-sample runtime into a log.

Requirements
:  - `NanoPlot` must be installed (see https://github.com/wdecoster/NanoPlot). Typically install via `pip` or `conda`.
  - GNU `parallel` (the script uses `parallel` for concurrency).

Usage
:  ./run_nanoplot.sh <INPUT_FOLDER> <OUTPUT_FOLDER> <LOG_FILE>

Example
:  ./run_nanoplot.sh /data/fastq_merged /data/nanoplot_output nanoplot.log

Notes & improvements
:  - The original script moves the log file inside the parallel job; this can cause race conditions. Prefer to keep the master log updated by the parent shell or append to a central log from within the parallel job safely (GNU parallel has `--results` / `--joblog` features that help).
  - If NanoPlot is not found, ensure it's installed and on PATH. Running `NanoPlot --version` should return quickly.

check_fastq_compression.sh and rename_fastq.sh
----------------------------------------------
These are helper utilities; read the top of each script for usage and options. Typical uses:
- `check_fastq_compression.sh <folder> [out.txt]` — scan for files that fail gzip checks and list them. If all files are valid (no corrupt or truncated files), it starts the transfer to the Datamover. 

rename_fastq.sh
-------------------------------
- `rename_fastq.sh <mapping_file> <fastq_dir>` — rename fastq files according to tab-delimited mapping.

transfer_batches_time_report.sh
-------------------------------
Runs the data transfer in batches with time gaps in between. It also generates a human-friendly report about batch transfer durations. Read the script header to see expected input files (logs produced during transfer) and output formats.

