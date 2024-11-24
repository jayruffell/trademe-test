# This script creates the input csv for the trademe-test.pbix file. The PBI report lets users estimate the value of either strategy A, strategy B, or a "dynamic" strategy that uses a model to dynamically pick either A or B each day based on each strategys' predicted conversion rate. The model won't be perfectly accurate, so users will be able to play around with model accuracy to see how this changes the effectiveness of the dynamic strategy.
# This script outputs a csv of conversion rate for each strategy, where conversion rate for "dynamic" is calculated under different scenarios of model accuracy. Conversion rates are calculated from the A/B test results provided by Trade Me.

rm(list = ls())
library(tidyverse)
source("helpers.r")

aggregated_data <- readr::read_csv("sql_input_202306csv-Sheet1.csv")

# calculate conversion rates from Strategy A and Strategy B, calculated from the A/B test data provided by Trade Me.
conv_rate_by_strategy <- aggregated_data %>%
    pivot_wider(names_from = session_result, values_from = session_count) %>%
    transmute(date_id, group_id, n = `0` + `1`, conversions = `1`, conversion_rate = `1` / (`0` + `1`)) %>%
    select(date_id, group_id, conversion_rate) %>%
    pivot_wider(names_from = group_id, values_from = conversion_rate)

# calculate conversion rates based on the "dynamic" strategy, i.e. using a model to predict whether A or B will perform better each day, where model accuracy is either 100%, 50%, or 75%. If accuracy is 100% the conversion rate will always be the greater of Strategy A and Strategy B from the A/B test data, if accuracy is 50% it will be the average of the two, and if it's 75% it will be a weighted average. 
conv_rate_by_strategy <- conv_rate_by_strategy %>%
    mutate(
        dynamic_100 = pmap_dbl(list(A, B, 1), pick_best_conversion_rate),
        dynamic_50 = pmap_dbl(list(A, B, 0.5), pick_best_conversion_rate),
        dynamic_75 = pmap_dbl(list(A, B, 0.75), pick_best_conversion_rate)
    )

# convert to long format so amenable to filtering in PBI
conv_rate_by_strategy_long <- conv_rate_by_strategy %>%
    pivot_longer(-date_id) %>%
    mutate(
        strategy = ifelse(grepl("dynamic", name), "dynamic", name),
        model_accuracy = ifelse(
            grepl("100", name), "100%",
            ifelse(grepl("75", name), "75%",
                ifelse(grepl("50", name), "50%", NA)
            )
        )
    ) %>%
    select(-name) %>%
    rename(conversion_rate_per_session = value)

# Replicate strategy A and strategy B rows for each value of model_accuracy - these are currently NA so disappear when filtering by model_accuracy in PBI.
temp_strat_A_and_B_data <- filter(
    conv_rate_by_strategy_long, strategy %in% c("A", "B")
)
conv_rate_by_strategy_long <- filter(
    conv_rate_by_strategy_long, !strategy %in% c("A", "B")
) %>%
    bind_rows(
        mutate(temp_strat_A_and_B_data, model_accuracy = "100%"),
        mutate(temp_strat_A_and_B_data, model_accuracy = "75%"),
        mutate(temp_strat_A_and_B_data, model_accuracy = "50%")
    )

# re-calc conv rates as diff versus the status quo (A)
conv_rate_strategy_A <- select(conv_rate_by_strategy, date_id, A)
conv_rate_by_strategy_long_diff <- conv_rate_by_strategy_long %>%
    left_join(conv_rate_strategy_A, by = "date_id") %>%
    mutate(conversion_rate_per_session = conversion_rate_per_session - A) %>%
    select(-A) %>%
    filter(strategy != "A")

conv_rate_by_strategy_final <- bind_rows(
    mutate(conv_rate_by_strategy_long, type = "absolute values"),
    mutate(conv_rate_by_strategy_long_diff, type = "difference vs A")
)

# save for ingestion into PBI
write.csv(conv_rate_by_strategy_final, "conv_rate_by_strategy_final.csv", row.names = FALSE)
