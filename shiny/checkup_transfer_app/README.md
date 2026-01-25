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

