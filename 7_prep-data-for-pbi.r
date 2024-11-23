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
