suppressWarnings(library(stringr))
suppressWarnings(suppressPackageStartupMessages(library(tidyverse)))

## functions
scim_file_exists = function(){
  "scimago_dat.csv" %in% list.files("../src_data/")
}

download_scim = function(){
  tryCatch({
    message("\n Downloading Scimago dataset. Stored in src_data")
    download.file(url = url_content, destfile = "../src_data/scimago_dat.csv")
    message("\n Download successful")
  }, warning = function(war) {
    print(paste("WARNING:  ",war))
  }, error = function(err) {
    print(paste("ERROR:  ",err))
  })
}


args = commandArgs(trailingOnly = T)
pub_fname = as.character(args[1])


## url for dataset from scimago
url_content = "https://www.scimagojr.com/journalrank.php?out=xls"

scim_download = ""
## prompt for downloading
if (!interactive()){
  if (scim_file_exists()){
    while (!(scim_download %in% c("Y", "N"))){
      cat("Scimago data already exists. Do you want to download the latest version? (Y / N) ")
      scim_download = readLines(file("stdin"),1)
    }
  }
}

## download only if answered "Y"
if (scim_download == "Y" | !scim_file_exists()){
  # download file from Scimago
  download_scim()
  message("\nLatest Scimago dataset downloaded into src_data/")
  
}

message("\n Now joining ", pub_fname, " with Scimago journal ranking\n")


### loading required tables
scimago = suppressWarnings(suppressMessages(read_delim("../src_data/scimago_dat.csv", delim = ";")))
journal_pubs_issns = suppressMessages(read_csv(paste0("../src_data/", pub_fname)))

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
scimago_processed = scimago %>% 
  separate(Issn, c("issn1", "issn2"), sep = ", ") %>% 
  gather("key", "ISSN", c("issn1", "issn2")) %>% 
  select(-key) %>% 
  mutate(ISSN = ifelse(nchar(ISSN)==7, paste0(ISSN, "X"), ISSN)) %>% ## if an ISSN contains only 7 characters then adding an "X" to the end to suit the standard
  filter(!is.na(ISSN) & ISSN != "-") %>% ## removing empty ISSNs in case there are any
  arrange(Title)

## joining Pubs dataset and Scimago dataset
joined_tables = journal_pubs_issn_processed %>% 
  left_join(scimago_processed, by = c("ISSN"="ISSN")) %>% ## using left outer join, to keep publications that don't have a journal in the Scimago list
  rename("journal_title" = "Title.y", "article_title"="Title.x") %>% 
  group_by(`DRO PID`) %>% 
  mutate(ISSN = paste(ISSN, collapse = ", ")) %>% 
  distinct(`DRO PID`, .keep_all = T) %>% 
  arrange(article_title)

## processing the joined tables further, cleaning up categories and Quartiles
joined_spltCats = joined_tables %>% 
  distinct(`DRO PID`, .keep_all = T) %>% 
  mutate(Categories = strsplit(Categories,"; ")) %>%
  unnest(Categories) %>% 
  mutate("Quartiles" = str_replace(Categories, "(.*)(\\(Q)(.*)(\\))", "\\3"), 
         Categories = str_replace(Categories, "(.*)(\\()(.*)(\\))", "\\1")) %>% 
  arrange(`DRO PID`)

## outputting both datasets
write_csv(joined_tables, "../output_data/joined_tables.csv")
write_csv(joined_spltCats, "../output_data/joined_tables_with_splt_categories.csv")

message("\n\nProcessing complete: You can find the data in the 'output_data' folder\n\n")