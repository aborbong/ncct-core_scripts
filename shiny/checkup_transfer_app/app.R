#!/usr/bin/env Rscript
library(shiny)
suppressMessages(library(readr))
suppressMessages(library(dplyr))
suppressMessages(library(stringr))
suppressMessages(library(DT))

if(getRversion() >= "2.15.1") utils::globalVariables(c("name", "ncct_filename"))

## A Shiny-friendly version of checkup_transfer that returns a list of results
checkup_transfer_shiny <- function(qportal_report_filepath, 
                                   demultiplexed_files_filepath = NULL, 
                                   transfer_date = NULL, 
                                   log_dir = ".", 
                                   qbic_barcode_prefix = NULL,
                                   ncct_input_folder = NULL){ 

  # Inputs validation
  if(missing(qportal_report_filepath) || is.null(qportal_report_filepath) || !file.exists(qportal_report_filepath)){
    stop("qPortal report file not provided or does not exist")
  }

   ## List files in the ncct input folder if provided, select only those with the qbic barcode prefix and .fastq.fz or .fq.gz extension
  if(is.null(demultiplexed_files_filepath)) {
    demultiplexed_files <- data.frame(
      ncct_filename = list.files(
        ncct_input_folder,
        pattern = paste0("^", qbic_barcode_prefix, ".*\\.(fastq|fq)\\.gz$")
        )
      )

  }
  else {
    #Import list of demultiplexed files and rename columns
    demultiplexed_files = suppressMessages(
      read_tsv(demultiplexed_files_filepath,col_names = "ncct_filename")
    )
  }

  ## Import qportal .tsv report and rename columns
  qportal_report <- suppressMessages(read_tsv(qportal_report_filepath))

  ## Evaluate if a single date or a range
  if(!is.null(transfer_date) && str_detect(transfer_date, "-")){
    date_range <- str_split(transfer_date, "-")[[1]]
    start_date <- date_range[1]
    end_date <- date_range[2]
    transfer_qportal <- qportal_report %>%
      filter(str_detect(name, paste0("_(", paste0(start_date, "|", end_date), ")\\d{6}_"))) %>%
      mutate(ncct_filename = str_remove(name, "_\\d{14}_"))
      print(transfer_qportal$ncct_filename)
  } else {
    transfer_qportal <- qportal_report %>%
      filter(str_detect(name, paste0("_", transfer_date, "\\d{6}_"))) %>%
      mutate(ncct_filename = str_remove(name, "_\\d{14}_"))
  }

  n_files_ncct <- nrow(demultiplexed_files)
  n_files_qportal <- nrow(transfer_qportal)

  missing_files <- setdiff(demultiplexed_files$ncct_filename, transfer_qportal$ncct_filename)
  total_files <- length(intersect(demultiplexed_files$ncct_filename, transfer_qportal$ncct_filename))
  total_unique_files <- length(unique(transfer_qportal$ncct_filename))
  total_unique_files_names <- unique(transfer_qportal$ncct_filename)

  duplicated_files <- transfer_qportal %>%
    group_by(ncct_filename) %>%
    filter(n() > 1) %>%
    distinct(ncct_filename) %>%
    pull(ncct_filename)

  # Prepare logging outputs
  if (!dir.exists(log_dir)) dir.create(log_dir, recursive = TRUE)
  timestamp <- format(Sys.time(), "%Y%m%d")
  log_base <- file.path(log_dir, paste0(timestamp, "_checkup_transfer_", transfer_date))
  log_file <- paste0(log_base, ".log")
  missing_file_out <- paste0(log_base, "_missing.txt")
  dup_file_out <- paste0(log_base, "_duplicates.txt")

  log_lines <- character()
  log_lines <- c(log_lines, paste0("Transfer Status Report: ", Sys.time()))
  log_lines <- c(log_lines, paste0("Transfer date: ", transfer_date))
  log_lines <- c(log_lines, paste0("QBIC barcode prefix: ", qbic_barcode_prefix))
  log_lines <- c(log_lines, paste0("Input folder: ", ncct_input_folder))
  log_lines <- c(log_lines, paste0("qPortal report file: ", qportal_report_filepath))
  log_lines <- c(log_lines, paste0("Source local files (NCCT): ", n_files_ncct))
  log_lines <- c(log_lines, paste0("Transferred files to the qPortal: ", n_files_qportal))
  log_lines <- c(log_lines, paste0("Valid unique files: ", total_files))
  log_lines <- c(log_lines, paste0("Duplicated files in the qPortal: ", paste0(duplicated_files, sep = "\n")))
  log_lines <- c(log_lines, paste0("Missing files in the qPortal: ", paste0(missing_files, collapse = ", ")))

  output_table <- data.frame(
    "File.Name" = c(duplicated_files, missing_files, total_unique_files_names),
    "Status" = c(rep("Duplicated", length(duplicated_files)), 
                 rep("Missing", length(missing_files)),
                 rep("Unique", length(total_unique_files_names))),
    stringsAsFactors = FALSE
  )

  write.table(output_table, file = file.path(log_dir, paste0(timestamp, "_checkup_transfer_", transfer_date, "_output.txt")), sep = "\t", row.names = FALSE, quote = FALSE)
  writeLines(log_lines, con = log_file)
  if (length(missing_files) > 0) writeLines(missing_files, con = missing_file_out) else writeLines(character(0), con = missing_file_out)
  if (length(duplicated_files) > 0) writeLines(duplicated_files, con = dup_file_out) else writeLines(character(0), con = dup_file_out)

  result <- list(
    n_files_ncct = n_files_ncct,
    ncct_input_folder = ncct_input_folder,
    qbic_barcode_prefix = qbic_barcode_prefix,
    n_files_qportal = n_files_qportal,
    missing_files = missing_files,
    duplicated_files = duplicated_files,
    total_files = total_files,
    total_unique_files = total_unique_files,
    output_table = output_table,
    log_lines = log_lines,
    demultiplexed_files = demultiplexed_files,
    log_paths = list(log_file = log_file, missing_file = missing_file_out, dup_file = dup_file_out)
  )

  return(result)

}


ui <- fluidPage(
  titlePanel("Check transfer status to the qPortal"),
  sidebarLayout(
    sidebarPanel(
      fileInput("qportal", "qPortal report (.tsv)", accept = c('.tsv', '.txt')),
      fileInput("demux", "(Optional) Demultiplexed filenames (.txt)", accept = c('.tsv', '.txt')),
      textInput("transfer_date", "Transfer date (YYYYMMDD) or data range (YYYYMMDD-YYYYMMDD)", value = "20251027"),
      textInput("qbic_prefix", "QBIC barcode prefix (optional)", value = "Q2181"),
      textInput("ncct_folder", "NCCT input folder (Optional: Required if demultiplexed filenames not provided)",value = "../../test_data/fastq_transfer/"),
      textInput("log_dir", "Log directory", value = "shiny_logs"),
      actionButton("run", "Run checkup"),
      actionButton("demo", "Run demo (test_data)"),
      width = 3
    ),
    mainPanel(
      verbatimTextOutput("summary"),
      h4("Missing files"),
      DT::dataTableOutput("missing_table"),
      h4("Duplicated files"),
      DT::dataTableOutput("dup_table"),
      h4("Output table"),
      DT::dataTableOutput("out_table"),

      downloadButton("download_output", "Download output table (.TSV)"),
      downloadButton("download_missing", "Download missing files (.TSV)"),
      downloadButton("download_dup", "Download duplicated files (.TSV)")
    )
  )
)

server <- function(input, output, session){
  # reactiveVal to store the last result (from run or demo)
  last_result <- reactiveVal(NULL)

  observeEvent(input$run, {
    req(input$qportal)
    qportal_path <- input$qportal$datapath
    demux_path <- NULL
    if(!is.null(input$demux)) demux_path <- input$demux$datapath

    qbic_prefix_val <- if (input$qbic_prefix == "") NULL else input$qbic_prefix
    ncct_folder_val <- if (input$ncct_folder == "") NULL else input$ncct_folder

    # call the function
    res <- tryCatch({
      rr <- checkup_transfer_shiny(
        qportal_report_filepath = qportal_path,
        demultiplexed_files_filepath = demux_path,
        transfer_date = input$transfer_date,
        log_dir = input$log_dir,
        qbic_barcode_prefix = input$qbic_prefix,
        ncct_input_folder = input$ncct_folder
      )
      list(success = TRUE, res = rr)
    }, error = function(e){
      list(success = FALSE, message = e$message)
    })

    last_result(res)
  })

  observeEvent(input$demo, {
    # Use test_data shipped in repository (relative to app directory)
    demo_qportal <- normalizePath(file.path("..", "..", "test_data", "251112_NCCT_VOOLSTRA_Q2181_Raw_Data.tsv"), mustWork = FALSE)
    demo_demux <- normalizePath(file.path("..", "..", "test_data", "demultiplexed_files.txt"), mustWork = FALSE)
   
 

    res <- tryCatch({
      rr <- checkup_transfer_shiny(
        qportal_report_filepath = demo_qportal,
        demultiplexed_files_filepath = demo_demux,
        transfer_date = input$transfer_date,
        log_dir = input$log_dir,
        qbic_barcode_prefix = input$qbic_prefix,
        ncct_input_folder = input$ncct_folder
      )
      list(success = TRUE, res = rr)
    }, error = function(e){
      list(success = FALSE, message = e$message)
    })

    last_result(res)
  })

  output$summary <- renderText({
    r <- last_result()
    if(is.null(r)) return("Click 'Run checkup' or 'Run demo' to start")
    if(!r$success) return(paste0("Error: ", r$message))
    res <- r$res
    paste0(
      "Transfer Status Summary:\n",
      "-----------------------------------\n",
      "Transfer date: ", input$transfer_date, "\n",    
      "Files present in the source folder at NCCT: ", res$n_files_ncct, "\n",
      "Files successfully transferred to the qPortal: ", res$n_files_qportal, "\n",
      "Valid unique files: ", res$total_files, "\n",
      "Duplicated files found: ", length(res$duplicated_files), "\n",
      "Missing files found: ", length(res$missing_files), "\n",
      "Logs written to:\n", 
      " ",paste(unlist(res$log_paths), collapse = ", ")
    )
  })

  output$out_table <- DT::renderDataTable({
    r <- last_result()
    req(r)
    if(!r$success) return(NULL)
    DT::datatable(r$res$output_table, options = list(pageLength = 25))
  })

  output$missing_table <- DT::renderDataTable({
    r <- last_result()
    req(r)
    if(!r$success) return(NULL)
    DT::datatable(data.frame(missing = r$res$missing_files), options = list(pageLength = 10))
  })

  output$dup_table <- DT::renderDataTable({
    r <- last_result()
    req(r)
    if(!r$success) return(NULL)
    DT::datatable(data.frame(duplicated = r$res$duplicated_files), options = list(pageLength = 10))
  })


  output$demultiplexed_files <- DT::renderDataTable({
    r <- last_result()
    req(r)
    if(!r$success) return(NULL)
    DT::datatable(data.frame(demultiplexed = r$res$demultiplexed_files), options = list(pageLength = 10))
  })

  output$download_output <- downloadHandler(
    filename = function(){ paste0('checkup_output_', Sys.Date(), '.tsv') },
    content = function(file){
      r <- last_result(); req(r); if(!r$success) stop(r$message)
      write.table(r$res$output_table, file = file, sep = "\t", row.names = FALSE, quote = FALSE)
    }
  )

  output$download_missing <- downloadHandler(
    filename = function(){ paste0('missing_files_', Sys.Date(), '.txt') },
    content = function(file){
      r <- last_result(); req(r); if(!r$success) stop(r$message)
      writeLines(r$res$missing_files, con = file)
    }
  )

  output$download_dup <- downloadHandler(
    filename = function(){ paste0('duplicated_files_', Sys.Date(), '.txt') },
    content = function(file){
      r <- last_result(); req(r); if(!r$success) stop(r$message)
      writeLines(r$res$duplicated_files, con = file)
    }
  )

  

}

shinyApp(ui, server)
