checkup_transfer = function(qportal_report_filepath, 
                              demultiplexed_files_filepath = NULL, 
                              transfer_date = NULL, 
                              log_dir = ".", 
                              qbic_barcode_prefix = NULL,
                              ncct_input_folder = NULL){ 

  ##load libraries
  suppressMessages(library(readr))
  suppressMessages(library(dplyr))
  suppressMessages(library(stringr))
  
  # Print used parameters for input files
  message("Using QBIC barcode prefix: ",qbic_barcode_prefix)
  message("Using input folder: ",ncct_input_folder)
  message("Using qPortal report file: ", qportal_report_filepath)

  ## List files in the ncct input folder if provided, select only those with the qbic barcode prefix and .fastq.fz or .fq.gz extension
  if(is.null(demultiplexed_files_filepath)) {
    demultiplexed_files = data.frame(
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
  qportal_report = suppressMessages(
    read_tsv(qportal_report_filepath)
  )
  
  ## Evaluate if a single date or a data range is provided
  if(str_detect(transfer_date,"-")){
    date_range = str_split(transfer_date,"-")[[1]]
    start_date = date_range[1]
    end_date = date_range[2]
    #filter files by transfer date range and create a column with the ncct filename
    transfer_qportal = qportal_report %>%
                    filter(str_detect(name, paste0("_(",paste0(start_date,"|",end_date),")\\d{6}_"))) %>%
                    mutate(ncct_filename = str_remove(name, "_\\d{14}_"))
  } else{
    #single date provided
    transfer_date = transfer_date
    #filter files by transfer date and create a column with the ncct filename
    transfer_qportal = qportal_report %>%
                    filter(str_detect(name, paste0("_",transfer_date,"\\d{6}_"))) %>%
                    mutate(ncct_filename = str_remove(name, "_\\d{14}_"))

  }

  
  
  ## Get the total of files in each location
  n_files_ncct = nrow(demultiplexed_files)
  
  n_files_qportal = nrow(transfer_qportal)
  
  ## Print a message with the total of local files (NCCT) and the qPortal
  message("Files present in the source folder at NCCT: ",n_files_ncct)
  message("Files successfully transferred to the qPortal: ",n_files_qportal)
  
  ## Find missing files in the qPortal (only present in ncct demultiplex results)
  missing_files = setdiff(demultiplexed_files$ncct_filename, transfer_qportal$ncct_filename)
  total_files = length((intersect(demultiplexed_files$ncct_filename, transfer_qportal$ncct_filename)))
  total_unique_files = length(unique(transfer_qportal$ncct_filename))
  total_unique_files_names = unique(transfer_qportal$ncct_filename)

  ##Find duplicated files in the qPortal
  duplicated_files = transfer_qportal %>%
                      group_by(ncct_filename) %>%
                      filter(n()>1) %>%
                      distinct(ncct_filename) %>%
                      pull(ncct_filename)

## Calculate elapsed time between files reaching QBic and being shown in the qPortal


## Print summary message for duplicated files
  if(length(duplicated_files)>0){
    message("Total of unique files in the qPortal for transfer date ",transfer_date,": ", total_unique_files)
    message("⚠️  Duplicated files found in the qPortal for transfer date ",transfer_date,": ", length(duplicated_files))
    message("Duplicates files are written to: ",log_dir)# log_dir,file.path(log_dir, paste0(timestamp,"_checkup_transfer_", transfer_date)),"_duplicates.txt")
    #print(duplicated_files)
  } else {
    message("Total unique files in qPortal for transfer date ",transfer_date,": ", total_unique_files)
    message("✅  No duplicated files found in the qPortal for transfer date ",transfer_date)
  }

    #Print summary message for number of transferred files
  if(length(missing_files)==0){
    message("✅  All ", total_files, " files for transfer date ",transfer_date," are present in the qPortal")}
  else{
    message("⚠️  Only ", total_files, " were transferred to the qPortal. The following files are missing in the qPortal for transfer date ",transfer_date,":")
    print(missing_files)
    
    
  }

  ## Prepare logging: ensure log directory exists and write summary + lists
  if (!dir.exists(log_dir)) dir.create(log_dir, recursive = TRUE)
  timestamp <- format(Sys.time(), "%Y%m%d")
  log_base <- file.path(log_dir, paste0(timestamp,"_checkup_transfer_", transfer_date))
  log_file <- paste0(log_base, ".log")
  missing_file_out <- paste0(log_base, "_missing.txt")
  dup_file_out <- paste0(log_base, "_duplicates.txt")


  log_lines <- character()
  log_lines <- c(log_lines, paste0("Transfer Completeness report: ", Sys.time()))
  log_lines <- c(log_lines, paste0("Transfer date: ", transfer_date))
  log_lines <- c(log_lines, paste0("QBIC barcode prefix: ", qbic_barcode_prefix))
  log_lines <- c(log_lines, paste0("Input folder: ", ncct_input_folder))
  log_lines <- c(log_lines, paste0("qPortal report file: ", qportal_report_filepath))
  log_lines <- c(log_lines, paste0("Source local files (NCCT): ", n_files_ncct))
  log_lines <- c(log_lines, paste0("Transferred files to the qPortal: ", n_files_qportal))
  log_lines <- c(log_lines, paste0("Valid unique files: ", total_files))
  log_lines <- c(log_lines, paste0("Duplicated files in the qPortal: "))
  log_lines <- c(log_lines, paste0(duplicated_files, collapse = ", "))
  log_lines <- c(log_lines, paste0("Missing files in the qPortal: ", paste0(missing_files, collapse = ", ")))

  ## Write output table 
  output_table <- data.frame(
    "File Name" = c(duplicated_files, missing_files,total_unique_files_names),
    "Status" = c(rep("Duplicated", length(duplicated_files)), 
                  rep("Missing", length(missing_files)),
                  rep("Unique",length(total_unique_files_names)))
  )
  write.table(output_table, 
              file = file.path(log_dir, paste0(timestamp,"_checkup_transfer_", transfer_date,"_output.txt")), 
              sep = "\t",  
              row.names = FALSE,
              quote = FALSE)
  
  ## write log files
  writeLines(log_lines, con = log_file)
  if (length(missing_files) > 0) writeLines(missing_files, con = missing_file_out) else writeLines(character(0), con = missing_file_out)
  if (length(duplicated_files) > 0) writeLines(duplicated_files, con = dup_file_out) else writeLines(character(0), con = dup_file_out)

  message("Logs written:")
  message("  ", log_file)
  message("  ", missing_file_out)
  message("  ", dup_file_out)



}