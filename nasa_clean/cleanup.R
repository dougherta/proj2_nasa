
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

# new complete data frame, file save, file reload
nasa_df <- combine_df_tot( all_dfs )
saveRDS( nasa_df, file = './data/nasa_df.RDS')
nasa_df <- readRDS( './data/nasa_df.RDS')



# change fy to date object
library(lubridate)
nasa_df$fy = as.character(nasa_df$fy)
tmp = paste0(nasa_df$fy, "0101")
tmp = as_date(tmp, tz = 'America/New_York')
nasa_df$fy = tmp


# Descriptive statistics of FY cost
fy_cost <- nasa_df %>% 
  group_by( fy ) %>%
  summarise( tot_cost = sum( fy_tot_cost ),
             avg_cost = mean( fy_tot_cost ), 
             median_cost = median( fy_tot_cost ),
             max_cost = max( fy_tot_cost ))

# from https://en.wikipedia.org/wiki/Budget_of_NASA create dataframe of annual budget 2008-2017
year = c(2008,2009,2010,2011,2012,2013,2014,2015,2016,2017)
percent = c(0.006,0.0057,0.0052,0.0051,0.005,0.0049,0.005,0.0049,0.005,0.0047)
annual = c(19700000,19714000,20423000,17833000,17471000,17219000,17647000,17989000,19037000,18841000)

fy_budget <- data.frame(fy=year, percent=percent, annual_budg=annual)

fy_budget$fy = as.character(fy_budget$fy)
tmp = paste0(fy_budget$fy, "0101")
tmp = as_date(tmp, tz = 'America/New_York')
fy_budget$fy = tmp

fy_overall <- inner_join(x = fy_budget, y = fy_cost, by = 'fy')
saveRDS( fy_overall, file = './data/ann_budg.RDS')


# Create gt Table of descriptive stats
library(gt)

fy_overall %>% 
  gt() %>% 
  tab_header(
    title = "Annual Budget of NASA for Fiscal Years 2008-2017",
    subtitle = "US Dollars"
  ) %>% 
  fmt_date( columns = vars(fy), 
            date_style = 10 
  ) %>% 
  fmt_percent(
    columns = vars(percent)
  ) %>% 
  cols_move(
    columns = vars(percent),
    after = vars(annual_budg)
  ) %>% 
  fmt_currency(
    columns = vars(annual_budg, tot_cost, avg_cost, median_cost, max_cost),
    currency = 'USD'
  ) %>% 
  cols_label(
    fy = "Fiscal Year",
    annual_budg = "Annual Budget: 2014 Constant Dollars",
    percent = "% of Fed Budget",
    tot_cost = "Total Research Spending",
    avg_cost = "Average Project Cost",
    median_cost = "Median Project Cost",
    max_cost = "Maximum Project Cost"
  ) %>% 
  tab_source_note(
    source_note = md("*Source Federal Budget: https://en.wikipedia.org/wiki/Budget_of_NASA*")
  ) %>% 
  cols_width(
    vars(fy) ~ px(50),
    vars(annual_budg) ~ px(125),
    vars(percent) ~ px(75),
    everything() ~ px(120)
  ) %>% 
  opt_row_striping()
  

library(RColorBrewer)

# Boxplot by fiscal year of total research costs
ggplot(nasa_df, aes(x = format(fy, '%Y'), y = fy_tot_cost/1000000)) +
  geom_boxplot() +
  labs(title='Total Cost by Fiscal Year',
       x = 'Fiscal Year',
       y = 'Cost in Hundred-Thousands') +
  theme_bw()


# Bar chart of total projects by fiscal year
projs <- nasa_df %>% 
  group_by( fy = format(fy, '%Y') ) %>% 
  summarise( count=n() )

  
ggplot(projs) +
  geom_col(aes(x = fy, y = count)) + 
  labs(title='Total Projects by Fiscal Year',
       x = 'Fiscal Year',
       y = 'Projects') +
  theme_classic() +
  scale_fill_grey()


count( distinct(nasa_df, proj_lead) )
count( distinct(nasa_df, organization) )
count( distinct(nasa_df, state) )
distinct(nasa_df, state)
count(distinct(nasa_df, proj_num))


# bar of top 20 research institutions over 10 years
org_filtered <- nasa_df %>%
  group_by( organization ) %>%
  summarise(count=n()) %>%
  top_n(20, count)

ggplot(data = org_filtered) +
  geom_bar(aes(x = reorder(organization, count), fill = count)) + 
  labs(title = 'Top 20 Research Institutes',
       x = '',
       y = 'Total Number of Projects') +
  coord_flip() + 
  theme_classic() 


# look at 3 most expensive projects per year for study concept and draw table
most_exp <- nasa_df %>% 
  select(
    fy, fy_tot_cost, abstract, organization, proj_lead, city, state
  ) %>% 
  group_by( fy ) %>% 
  arrange(desc(fy_tot_cost)) %>% 
  top_n(3, fy_tot_cost) %>% 
  arrange(fy)
view(most_exp)


most_exp %>% 
  gt() %>% 
  tab_header(
    title = "Specific Projects",
    subtitle = "Top 3 per Fiscal Year"
  ) %>% 
  fmt_date(
    columns=vars(fy), date_style = 10
  ) %>% 
  fmt_currency(
    columns = vars(fy_tot_cost),
    currency = 'USD'
  ) %>% 
  cols_label(
    fy = 'Fiscal Year',
    fy_tot_cost = 'Award Total',
    abstract = 'Abstract',
    organization = 'Organization',
    proj_lead = 'Principal Researcher',
    city = 'City',
    state = 'State'
  )
  

# random sample of 10 projects
rand <- nasa_df %>% 
  select(
    fy, fy_tot_cost, abstract, organization, proj_lead, city, state
  ) %>% 
  sample_n(size = 10, replace = T) %>% 
  arrange(fy)
view(rand)

rand %>% 
  gt() %>% 
  tab_header(
    title = "Specific Projects",
    subtitle = "10 Chosen by random selection"
  ) %>% 
  fmt_date(
    columns=vars(fy), date_style = 10
  ) %>% 
  fmt_currency(
    columns = vars(fy_tot_cost),
    currency = 'USD'
  ) %>% 
  cols_label(
    fy = 'Fiscal Year',
    fy_tot_cost = 'Award Total',
    abstract = 'Abstract',
    organization = 'Organization',
    proj_lead = 'Principal Researcher',
    city = 'City',
    state = 'State'
  )


# filter by state for mapping
distinct(nasa_df, country)

st_filtered <- nasa_df %>% 
  filter( country == "UNITED STATES" ) %>% 
  group_by( state ) %>% 
  summarise(count=n())

# download US map data
library(usmap)

# plot US map of project numbers
plot_usmap( data = st_filtered, values = 'count', color = "blue" ) +
  scale_fill_continuous( low = "white", high = "blue", name = "Projects", label = scales::comma ) +
  labs(title = 'Research Projects by State', subtitle = 'Aggregate of projects from 2008 to 2017') +
  theme( legend.position = "right")


# write file to csv for importing to Python for NLP analysis
write_csv( nasa_df, path = './data/nasa2008_17.csv' )
