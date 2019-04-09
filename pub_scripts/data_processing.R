suppressWarnings(library(stringr))
suppressWarnings(suppressPackageStartupMessages(library(tidyverse)))

src_data_path = "src_data"
#output_data_path = "output_data"
url_content = "https://www.scimagojr.com/journalrank.php?out=xls" ## url for dataset from scimago

args = commandArgs(trailingOnly = T)
pub_fname = as.character(args[1])

## catch if filename not provided
if (is.na(pub_fname)) stop("ERROR: Missing filename for publication data. This data should be in the src_data folder")
## catch if src_data folder doesn't exist
if (!dir.exists(src_data_path)) stop("src_data folder doesn't exist. You must have this folder with the DRO dataset in it.")

## functions
scim_file_exists = function(){
  TRUE %in% grepl("scimago*", list.files(src_data_path))
}

download_scim = function(){
  tryCatch({
    message(paste0("\nDownloading Scimago dataset. Stored in ", src_data_path))
    download.file(url = url_content, destfile = file.path(src_data_path, "scimago.csv"))
    message("\nDownload successful")
  }, warning = function(war) {
    print(paste("WARNING:  ",war))
  }, error = function(err) {
    print(paste("ERROR:  ",err))
  })
}

to_download = ""
## prompt for downloading
if (!interactive()){
  if (scim_file_exists()){
    while (!(to_download %in% c("Y", "N"))){
      cat("Scimago data already exists. Do you want to download the latest version? (Y / N) ")
      to_download = toupper(readLines(con = file("stdin"), n = 1))
    }
  }
}

## download only if answered "Y"
if (to_download == "Y" | !scim_file_exists()){
  download_scim() # download file from Scimago
  message("\nLatest Scimago dataset downloaded into src_data/")
}

message("\n Now joining '", pub_fname, "' with Scimago journal ranking\n")

## prompt for name of output file
out_name = NA
if (!interactive()){
  while (is.na(out_name)){
      cat("What do you want to name the output file? ")
      out_name = toupper(readLines(con = file("stdin"), n = 1))
  }
}

## create output_data folder if it doesn't exist
if (!dir.exists(out_name)) dir.create(out_name)


### loading required tables
scimago = suppressWarnings(suppressMessages(read_delim(file.path(src_data_path, "scimago.csv"), delim = ";", 
                     col_types = cols(SJR = "c"))))
journal_pubs_issns = suppressMessages(read_csv(file.path(src_data_path, pub_fname)))

## processing journal publications data from DRO 
## to clean up ISSNs into a state that matches the scimago dataset
journal_pubs_issn_processed = journal_pubs_issns %>% 
  group_by(`Parent Publication`) %>% # grouping by journal in order to merge ISSNs
  mutate(ISSN = paste(ISSN, collapse = ",")) %>%
  ungroup() %>% 
  mutate(ISSN = str_remove_all(string = .$ISSN, pattern =  "-"), 
         ISSN = str_split(ISSN, ",")) %>%
  unnest(ISSN)

## transforming scimago into a one-row-per-ISSN format
scimago_processed = suppressWarnings(scimago %>% 
  separate(Issn, c("issn1", "issn2"), sep = ", ") %>% 
  gather("key", "ISSN", c("issn1", "issn2")) %>% 
  select(-key) %>%
  mutate(ISSN = ifelse(nchar(ISSN)==7, paste0(ISSN, "X"), ISSN)) %>% ## if an ISSN contains only 7 characters then adding an "X" to the end to suit the standard
  filter(!is.na(ISSN) & ISSN != "-")) %>% ## removing empty ISSNs in case there are any
  mutate(SJR = str_replace(.$SJR, ",", "."))

## joining Pubs dataset and Scimago dataset
joined_tables = journal_pubs_issn_processed %>% 
  select(-SJR) %>% 
  left_join(scimago_processed, by = c("ISSN"="ISSN")) %>% ## using left outer join, to keep publications that don't have a journal in the Scimago list
  rename("journal_title" = "Title.y", "article_title"="Title.x") %>% 
  group_by(`DRO PID`) %>% 
  mutate(ISSN = paste(ISSN, collapse = ", ")) %>%
  ungroup() %>% 
  mutate(Categories = str_replace_all(.$Categories, "; ", "\n")) %>% 
  distinct(`DRO PID`, .keep_all = T) %>% 
  select(-c(Rank, Sourceid, journal_title, Type, 
            starts_with("Total"), 
            starts_with("Cit"), 
            starts_with("Ref"), Country, Publisher)) %>% 
  arrange(article_title) %>% 
  select(13, 7, 2, 4:6, 19, 16:18, 10, 8:9, 11:12, c(1, 15, 3, 14))

## processing the joined tables further, cleaning up categories and Quartiles
joined_spltCats = joined_tables %>% 
  distinct(`DRO PID`, .keep_all = T) %>% 
  mutate(Categories = strsplit(Categories,"\n")) %>%
  unnest(Categories) %>% 
  mutate(Quartiles = str_replace(Categories, "(.*)(\\(Q)(.*)(\\))", "\\3"), 
         Categories = str_replace(Categories, "(.*)(\\()(.*)(\\))", "\\1")) %>% 
  arrange(`DRO PID`) %>% 
  select(1:6, 19:20, 7:18)

## outputting both datasets
write_csv(joined_tables, file.path(out_name, paste0("DRO2scim_", out_name, ".csv")))
write_csv(joined_spltCats, file.path(out_name, paste0("DRO2scim-spltcats_", out_name, ".csv")))

message(paste0("\n\nProcessing complete: You can find the data in the '", out_name, "' folder\n\n"))
