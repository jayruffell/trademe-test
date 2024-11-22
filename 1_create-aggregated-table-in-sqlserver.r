# creates table in TradeMeTest SQL Server DB matching orig csv data

library(tidyverse)
source("helpers.r")

con <- connect_to_db()

# create SQL table and add data
if (!DBI::dbExistsTable(con, "dataAggregated")) {
    sql_data_aggregated <- readr::read_csv("sql_input_202306csv-Sheet1.csv")
    copy_to(con, sql_data_aggregated, "dataAggregated", overwrite = TRUE, temporary = FALSE)
} else {
    print("dataAggregated table already exists - skipping")
}