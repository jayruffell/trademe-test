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

# This function simulates using a model to dynamically pick the best performing strategy, then returns the conversion rate for that strategy. Since model predictions are imperfect it will return the expected conversion rate based on the probability the model picks correctly - see examples for details.
# # PARAMS
# - conversion_rate_A: conversion rate (as scalar proportion) for strategy A.
# - conversion_rate_B: as above.
# - Model_accuracy: a scalar proportion giving the probability the model will correctly pick the highest conversion rate.
# # EXAMPLES
# pick_best_conversion_rate(0.2, 0.3, 1.0)  # returns 0.3
# pick_best_conversion_rate(0.3, 0.2, 1.0)  # returns 0.3
# pick_best_conversion_rate(0.2, 0.3, 0.5)  # returns 0.25
# pick_best_conversion_rate(0.2, 0.3, 0.75)  # returns 0.275
pick_best_conversion_rate <- function(
    conversion_rate_A, conversion_rate_B, model_accuracy) {
    worst_rate <- min(conversion_rate_A, conversion_rate_B)
    difference_in_rates <- abs(conversion_rate_A - conversion_rate_B)
    return(worst_rate + model_accuracy * difference_in_rates)
}

