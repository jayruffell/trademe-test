library(tidyverse)
library(DBI)
library(odbc)

sql_data <- readr::read_csv("sql_input_202306csv-Sheet1.csv")
sql_data

# Establish the connection
con <- dbConnect(odbc(),
                 Driver = "ODBC Driver 17 for SQL Server",
                 Server = "DESKTOP-JGNU8D2\\SQLDEV",  # Server name with instance
                 Database = "TradeMeTest",              # Target database
                 Trusted_Connection = "Yes",        # Equivalent to "trusted_connection=yes"
                 Encrypt = "Yes",                   # Equivalent to "encrypt=yes"
                 TrustServerCertificate = "Yes")    # Equivalent to "trustServerCertificate=yes"
con

# create SQL table and add data
copy_to(con, sql_data, "dataAggregated", overwrite = TRUE, temporary = FALSE)

dbDisconnect(con)
