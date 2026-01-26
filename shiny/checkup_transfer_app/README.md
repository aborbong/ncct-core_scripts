# Checkup qPortal Transfer Status - ShinyApp

This small Shiny app runs the `CheckTransferCompleteness_qPortal.Rmd` notebook interactively. It reads a qPortal report (.tsv) and a list of demultiplexed files (alternatively, the QBIC barcode prefix and demultiplexed folder path can be provided), and the transfer date, then reports missing and duplicated files and writes logs and summary reports.

## How to run

Make sure you're located at the project root. Otherwise, modify the path accordingly.

From R:

```
library(shiny)
shiny::runApp('shiny/checkup_transfer_app', launch.browser = TRUE)
```

From the shell/terminal:

```bash
R -e "shiny::runApp('shiny/checkup_transfer_app', launch.browser=TRUE)"
```

Interactively from RStudio: 

Open the app.R file in RStudio and click the Run App button on the top right of the console to launch the session. 

Usage

- Upload a `qPortal` `.tsv` file (it should contain a `name` column for parsing).
- Optionally upload `demultiplexed_files.txt` (one-column list of demultiplexed files). If not provided, specify in `NCCT input folder` the path to the folder containing the demultiplexed .fastq.gz files (e.g. project_ID/demultiplex_results/flowcell_ID/NA), and provide the 5-character `QBIC barcode prefix` (e.g. Q2181).
- Set the `Transfer date` (YYYYMMDD) or a date range YYYYMMDD-YYYYMMDD. Example: 20260126, or 20260126-20260127
- Click `Run checkup` to run the checkup with your files, or `Run demo (test_data)` to run with the repository `test_data` example files.
- Interactive tables allow sorting and searching. You can download the reports (.TSV) using the buttons at the bottom of the page. 

Notes

- The demo uses the files in `test_data/` stored in this repository.
- Log files and output are written to the `Log directory` you set in the UI (default `shiny_logs`).
