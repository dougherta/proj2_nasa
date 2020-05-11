
# clean up and data wrangling for webscraping project of NASA research funding details from 2008 to 2017

library(tidyverse)


# create char vector of filenames from data directory
csv_filenames <- list.files( path = './data', pattern = 'csv' )

# create char vector of filepaths 
csv_filepaths <- paste0( './data/', csv_filenames, sep = '' )

# create list of data frames, strings not converted to factors 
all_dfs <- lapply( csv_filepaths, FUN = function( fp ) read.csv( fp, stringsAsFactors = F) )

# save all_dfs
saveRDS( all_dfs, file = './data/all_dfs.RDS' )

# read all_dfs.RDS if necessary
all_dfs <- readRDS( './data/all_dfs.RDS' )

# clean up date strings
clean_date_str <- function( date_str ){
  require( lubridate )
  parse_date_time( date_str, orders = c('dmY','Ymd','mdY','mdy') )
}

# format to date type: award_notice, proj_end, proj_start
fmt_df_dates <- function( df ){
  require( dplyr )
  df %>% mutate_at( c('award_notice', 'proj_end', 'proj_start'), clean_date_str )
}


# clean up fiscal year total cost strings
clean_fy_cost_str <- function( fy_cost_str ){
  no_fund = 'No funding information available for Project Number: '
  cleaned_str = gsub( pattern = paste0(no_fund,'[[:alnum:]]*'), replacement = '0.00', x = fy_cost_str )
  cleaned_str = gsub( pattern = '[^0-9.]', replacement = '', x = cleaned_str )  
  as.double( cleaned_str )
}

fmt_df_fyCost <- function( df ){
  require( dplyr )
  df %>% mutate_at( c('fy_tot_cost'), clean_fy_cost_str )
}

# combine all data frames into single, stacked data frame
combine_df_tot <- function( df_list ){
  lapply( df_list, function(df) fmt_df_fyCost( fmt_df_dates(df) ) ) %>% 
    bind_rows()
}


nasa_df <- combine_df_tot( all_dfs )
