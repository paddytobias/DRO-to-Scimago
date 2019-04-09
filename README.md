# Joining Publication data with Scimago
Paddy Tobias and Ellyse Mitchell, 2019

This program is intended to help research librarians to respond to academic requests for impact metrics on a publications list. 

The [program](pubs_scripts/data_processing.R) is designed to take one argument, the name of the file export from DRO containing the academic's publication data along with journal ISSNs. 

The program then checks to see if the Scimago journal ranking dataset exists. If it doesn't the program will download the Scimago data, placing it in `src_data/` folder; if it does exist, the user will be asked if they want to fetch the latest Scimago list. 

The program then writes two files to `output_data/` folder:
1. `joined_tables.csv` - this table represents the basic join of the Scimago data with the academic's publication list. Expect that some rows will contain NAs which indicate where the Scimago data didn't contain the journal that the academic had published in
2. `joined_tables_with_splt_categories.csv` - this table is a derivative of the first, but includes cleaned up categories and quartiles that the academic has published in. It is in a one-row-per-category format, and therefore contains duplications in the publication data (because one publication can be filed under  more than one category).

## Set up
Before you run the program, you will need to install the R dependencies. You can do this by running:

`Rscript pub_scripts/install_dependencies.R`

## Example execution 
`cd path/to/DRO_scimago_join/`

`Rscript pub_scripts/data_processing.R Pubs-Elements-ISSN.csv`


