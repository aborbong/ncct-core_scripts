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
- `corrupted_fastq_files.txt`, `valid_fastq_files.txt`, `transferred_files.log` — example output/log files used by some scripts or tests.

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

Troubleshooting
:  - "zcat: can't stat: ... No such file or directory" — indicates the glob didn't match any files; check the input path and confirm files exist. The script now checks for this case and logs a skip.
  - If rename conflicts happen (target exists), the current behavior is to `mv -f` (overwrite). Modify if you want skipping instead.

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
- `check_fastq_compression.sh <folder> [out.txt]` — scan for files that fail gzip checks and list them.
- `rename_fastq.sh <mapping_file> <fastq_dir>` — rename fastq files according to tab-delimited mapping.

transfer_batches_time_report.sh
-------------------------------
Generate a human-friendly report about batch transfer durations. Read the script header to see expected input files (logs produced during transfer) and output formats.

General notes
-------------
- Shell compatibility: scripts use bash features like arrays and `[[ ]]`. Use bash (`/usr/bin/env bash`) to run them.
- Logging: Many scripts accept an optional `LOG_FILE` path and use a `log_message()` helper. Provide an absolute path if you run scheduled jobs so you don't confuse relative paths.
- Dry-run: For destructive operations (concatenate/rename), test with `--dry-run` style behavior — either run a copy of the script that echoes commands instead of running them, or test in the `test_data` directory included in the repo.
- Dependencies: `gzip`/`pigz`, `parallel`, `NanoPlot`, standard POSIX tools (awk/sed). On macOS `zcat` may be named `gzcat`, so prefer `gzip -dc` for portability.

Testing with repo test data
--------------------------
This repo includes `test_data/` with small example inputs. Example test command from the repo root:

```bash
./scripts/bash/concatenate_nanopore_files.sh test_data/nanopore_test/test_pass test_data/nanopore_test/test_fail test_data/nanopore_test/test_output test_data/nanopore_test/map_file_nanopore.tsv test.log
```

After generating outputs you can run NanoPlot in dry-run (or real run) using:

```bash
./scripts/bash/run_nanoplot.sh test_data/nanopore_test/test_output test_data/nanopore_test/test_output_nanoplot nanoplot.log
```

If you run NanoPlot for real, ensure your environment has NanoPlot and GNU parallel installed.

Contributing / improvements
---------------------------
- Consider adding a `--dry-run` / `--force` flags to scripts that perform destructive changes.
- Use `getopt` or `argbash` to provide a more robust CLI and help message.
- Add unit tests (small fastq samples) and a CI job that runs the scripts in dry-run mode.

License / authorship
--------------------
These scripts are part of the `ncct-core_scripts` repository. See the repo top-level `LICENSE` and `README.md` for license and author details.
