# NOTE i shifted this to a notebook - see that file for final version (code all same, just re-ordered)

library(tidyverse)
source("helpers.r")

con <- connect_to_db()
sql_expanded <- collect(tbl(con, "dataExpanded")) %>%
    mutate(date_id = as.Date(date_id, format = "%d/%m/%Y"))
DBI::dbDisconnect(con)

sql_aggregated <- sql_expanded %>%
    group_by(date_id, group_id, session_result) %>%
    summarise(session_count = length(session_result))

# check what the trends are in the raw data
p1 <- sql_expanded %>%
    sample_n(50000) %>%
    ggplot(aes(date_id, session_result, colour = group_id)) +
    geom_jitter(alpha = 0.3, position = position_jitterdodge(jitter.height = 0.1)) + 
    geom_smooth()
# print(p1)

# and in the aggregated data
conv_rate_data <- sql_aggregated %>%
    pivot_wider(names_from = session_result, values_from = session_count) %>%
    transmute(date_id, group_id, n = `0` + `1`, conversions = `1`, conversion_rate = `1` / (`0` + `1`))
p2 <- conv_rate_data %>%
    ggplot(aes(date_id, conversion_rate, colour = group_id)) +
    geom_point() # + geom_smooth()
# print(p2)

# add in conf intervals - *check if these need updating for sample population*
ci_data <- Hmisc::binconf(x = conv_rate_data$conversions, n = conv_rate_data$n, return.df = TRUE)
conv_rate_data <- bind_cols(conv_rate_data, ci_data)

# plot raw count data with point estimates and conf intervals
p3 <- sql_expanded %>%
    # sample_n(50000) %>%
    ggplot(aes(date_id, session_result, colour = group_id)) +
    geom_jitter(alpha = 0.15, position = position_jitterdodge(jitter.height = 0.1)) + 
    # geom_smooth() +
    geom_pointrange(
    data = conv_rate_data,
    aes(x = date_id, y = PointEst, ymin = Lower, ymax = Upper, colour = group_id),
    size = 1
  ) + xlab("date") + ylab("conversion rate")
# print(p3)
# ggsave("conv rate by group.png", p3)

# add in overall values
sql_expanded_overall <- sql_expanded %>%
    mutate(date_id = "OVERALL")
sql_expanded_combined <- sql_expanded %>%
    mutate(date_id = as.character(date_id)) %>%
    bind_rows(sql_expanded_overall)

conv_rate_data_overall <- conv_rate_data %>%
    group_by(group_id) %>%
    summarise(n = sum(n), conversions = sum(conversions)) %>%
    mutate(conversion_rate = conversions / n) %>%
    mutate(date_id = "OVERALL")
ci_data_overall <- Hmisc::binconf(x = conv_rate_data_overall$conversions, n = conv_rate_data_overall$n, return.df = TRUE)
conv_rate_data_overall <- bind_cols(conv_rate_data_overall, ci_data_overall)
conv_rate_data_combined <- bind_rows(
    mutate(conv_rate_data, date_id = as.character(date_id)), conv_rate_data_overall
    )

p4 <- sql_expanded_combined %>%
# sample_n(5000) %>%
    ggplot(aes(date_id, session_result, colour = group_id)) +
    geom_jitter(alpha = 0.15, position = position_jitterdodge(jitter.height = 0.1)) + 
    geom_pointrange(
    data = conv_rate_data_combined,
    aes(x = date_id, y = PointEst, ymin = Lower, ymax = Upper, colour = group_id),
    size = 1
  ) + xlab("date") + ylab("conversion rate") +
  theme(
    text = element_text(size = 30),
    axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1))
ggsave("conv rate by group.png", p4, width = 15, height = 15)

# weekday effect? Nothing major. Biggest diff is Thurs. BUT only covers 10d so hard to analyse fully.
p10 <- conv_rate_data %>%
    mutate(dow = wday(date_id, label = TRUE, abbr = FALSE, week_start = 1)) %>%
    ggplot(aes(dow, conversion_rate, colour = group_id)) +
    geom_point(size = 5) +
  theme(
    text = element_text(size = 30),
    axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1))
# print(p10)
ggsave("conv rate by dow.png", p10, width = 15, height = 15)

# what about differences in proportions? 
dfs_list_by_date <- conv_rate_data_combined %>%
    group_by(date_id) %>%
    group_split()
conv_rate_diffs_df <- map_df(dfs_list_by_date, calc_ci_for_diff_of_propns)

p5 <- conv_rate_diffs_df %>% 
ggplot(aes(date_id, point_estimate_diff)) +
    geom_pointrange(
        data = conv_rate_diffs_df,
        aes(x = date_id, y = point_estimate_diff, ymin = lower_ci_diff, ymax = upper_ci_diff),
        size = 1
    ) + 
    geom_abline(slope = 0, intercept = 0, colour = "red") + xlab("date") + ylab("difference in conversion rate (A minus B)") +
  theme(
    text = element_text(size = 30),
    axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1))
# print(p5)
ggsave("conv_rate_diffs.png", p5, height = 15, width = 15)

# anything interesting in terms of conversion rate or website usage over time?
p6 <- sql_aggregated %>%
    mutate(
        session_result = ifelse(session_result == 1, "sessions that converted", "sessions that didnt convert")
    ) %>%
    bind_rows(sql_aggregated %>%
        group_by(date_id, group_id) %>%
        summarise(session_count = sum(session_count)) %>%
        mutate(session_result = "total sessions")) %>%
    ggplot(aes(date_id, session_count, colour = group_id)) +
    geom_line() +
    facet_wrap(~session_result, ncol = 1) +
    theme(
        text = element_text(size = 30),
        axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1)
    )
ggsave("sessions_over_time.png", p6, height = 15, width = 15)

# save csvs for ingestion into PBI
write.csv(conv_rate_data_combined, "conv_rate_data_combined.csv", row.names = FALSE)
write.csv(conv_rate_diffs_df, "conv_rate_diffs_df.csv", row.names = FALSE)
