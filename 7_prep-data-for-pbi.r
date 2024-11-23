# In PBI I will have a visual that lets users estimate the value of either strategy A, strategy B, or a "dynamic" strategy that uses a model to select either A or B each day. The model won't be perfectly accurate, so users will be able to play around with model accuracy.
# This script will output a df of conversion rate based on each strategy, and PBI users will be able to input users affected and value per conversion to visualise the value of investing in each strategy.
# These numbers will be broken down into (1) absolute conversion rate vs difference compared with strategy A (the status quo), and (2) different levels of model accuracy for the dynamic strategy. These will be used as slicer values in PBI.

library(tidyverse)
source("helpers.r")

aggregated_data <- readr::read_csv("sql_input_202306csv-Sheet1.csv")

conv_rate_by_strategy <- aggregated_data %>%
    pivot_wider(names_from = session_result, values_from = session_count) %>%
    transmute(date_id, group_id, n = `0` + `1`, conversions = `1`, conversion_rate = `1` / (`0` + `1`)) %>%
    select(date_id, group_id, conversion_rate) %>%
    pivot_wider(names_from = group_id, values_from = conversion_rate)

# calculate conversions based using a "dynamic" strategy, i.e. using a model to predict whether A or B will perform better each day, where model accuracy is either 100%, 50%, or 75%
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
            grepl("100", name), "100",
            ifelse(grepl("75", name), "75",
                ifelse(grepl("50", name), "50", NA)
            )
        )
    ) %>%
    select(-name) %>%
    rename(conversion_rate = value)

# re-calc conv rates as diff versus the status quo (A)
conv_rate_strategy_A <- select(conv_rate_by_strategy, date_id, A)
conv_rate_by_strategy_long_diff <- conv_rate_by_strategy_long %>%
    left_join(conv_rate_strategy_A, by = "date_id") %>%
    mutate(conversion_rate = conversion_rate - A) %>%
    select(-A)

conv_rate_by_strategy_final <- bind_rows(
    mutate(conv_rate_by_strategy_long, type = "absolute"),
    mutate(conv_rate_by_strategy_long_diff, type = "diff")
)
write.csv(conv_rate_by_strategy_final, "conv_rate_by_strategy_final.csv", row.names = FALSE)

# double check long data captured everything correctly
conv_rate_by_strategy_final %>%
ggplot(aes(date_id, conversion_rate)) + 
geom_point() + 
facet_grid(vars(strategy, model_accuracy), vars(type))
