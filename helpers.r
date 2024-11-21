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

calc_ci_for_diff_of_propns <- function(date_i_df) {
    # assumes a df with two rows, one for group A and one for group B, with sample size and number of conversions as cols. For each date there should be 2 rows, hence date_i_df as name

    stopifnot(nrow(date_i_df) == 2)
    test_result <- prop.test(
        x = date_i_df$conversions, n = date_i_df$n,
        correct = FALSE
    ) # only needed for small sample sizes

    # View the confidence interval
    point_estimate_diff <- test_result$estimate[1] - test_result$estimate[2]
    lower_ci_diff <- test_result$conf.int[1]
    upper_ci_diff <- test_result$conf.int[2]
    result <- data.frame(
        date_id = unique(date_i_df$date_id), point_estimate_diff, lower_ci_diff, upper_ci_diff
        )
    row.names(result) <- NULL
    return(result)
}
