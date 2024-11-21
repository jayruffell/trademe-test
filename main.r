library(tidyverse)
library(DBI)
library(odbc)

sql_data_aggregated <- readr::read_csv("sql_input_202306csv-Sheet1.csv")
sql_data_aggregated

# Establish the connection
con <- dbConnect(odbc(),
    Driver = "ODBC Driver 17 for SQL Server",
    Server = "DESKTOP-JGNU8D2\\SQLDEV", # Server name with instance
    Database = "TradeMeTest", # Target database
    Trusted_Connection = "Yes", # Equivalent to "trusted_connection=yes"
    Encrypt = "Yes", # Equivalent to "encrypt=yes"
    TrustServerCertificate = "Yes"
) # Equivalent to "trustServerCertificate=yes"
con

# create SQL table and add data
if (!dbExistsTable(con, "dataAggregated")) {
    copy_to(con, sql_data_aggregated, "dataAggregated", overwrite = TRUE, temporary = FALSE)
} else {
    print('dataAggregated table already exists - skipping')
}

# ---------------------------------------------------
# Create SQL table of expanded data (TrademeTest.dbo.dataExpanded) before continuing - see SQL scripts.
# ---------------------------------------------------

# check expansion worked
sql_expanded <- collect(tbl(con, "dataExpanded"))
sql_data_aggd_recalculated <- sql_expanded %>%
    group_by(date_id, group_id, session_result) %>%
    summarise(session_count = length(session_result))

equal_dfs <- all.equal(
    # reorder original df - was ordered by date, but date now handled as character.
    as.data.frame(arrange(sql_data_aggregated, date_id, group_id, session_result)),
    as.data.frame(sql_data_aggd_recalculated)
)
print(sprintf("dfs are equal: %s", equal_dfs))

dbDisconnect(con)