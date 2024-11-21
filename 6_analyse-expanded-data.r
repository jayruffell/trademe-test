
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
sql_expanded %>%
    sample_n(50000) %>%
    ggplot(aes(date_id, session_result, colour = group_id)) +
    geom_jitter(alpha = 0.3, position = position_jitterdodge(jitter.height = 0.1)) + 
    geom_smooth()

# and in the aggregated data
conv_rate_data <- sql_aggregated %>%
    pivot_wider(names_from = session_result, values_from = session_count) %>%
    transmute(date_id, group_id, n = `0` + `1`, conversions = `1`, conversion_rate = `1` / (`0` + `1`))
conv_rate_data %>%
ggplot(aes(date_id, conversion_rate, colour = group_id)) +
    geom_point() # + geom_smooth()

# add in conf intervals
ci_data <- Hmisc::binconf(x = conv_rate_data$conversions, n = conv_rate_data$n, return.df = TRUE)
conv_rate_data <- bind_cols(conv_rate_data, ci_data)

# plot raw count data with conf intervals
sql_expanded %>%
    sample_n(50000) %>%
    ggplot(aes(date_id, session_result, colour = group_id)) +
    geom_jitter(alpha = 0.3, position = position_jitterdodge(jitter.height = 0.1)) + 
    # geom_smooth() +
    geom_pointrange(
    data = conv_rate_data,
    aes(x = date_id, y = PointEst, ymin = Lower, ymax = Upper, colour = group_id),
    size = 1
  )

