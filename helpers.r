connect_to_db <- function() {
    con <- DBI::dbConnect(odbc::odbc(),
        Driver = "ODBC Driver 17 for SQL Server",
        Server = "DESKTOP-JGNU8D2\\SQLDEV",
        Database = "TradeMeTest",
        Trusted_Connection = "Yes",
        Encrypt = "Yes",
        TrustServerCertificate = "Yes"
    )
    return(con)
}