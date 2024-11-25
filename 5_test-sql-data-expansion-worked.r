# check that expanded data matches original csv file when grouped and summarised

library(tidyverse)
source("helpers.r")

con <- connect_to_db()
sql_expanded <- collect(tbl(con, "dataExpanded"))

# replace with version cald as SQL result set, rather than saved to DB.
sql_expanded <- readr::read_csv("sql_expanded_data_test.csv")
orig_data_recalculated <- sql_expanded %>%
    group_by(date_id, group_id, session_result) %>%
    summarise(session_count = length(session_result))

orig_data <- readr::read_csv("sql_input_202306csv-Sheet1.csv")

equal_dfs <- all.equal(
    # reorder original df - was ordered by date, but date now handled as character.
    as.data.frame(arrange(orig_data, date_id, group_id, session_result)),
    as.data.frame(orig_data_recalculated)
)
print(sprintf("dfs are equal: %s", equal_dfs))
print(head(sql_expanded))

DBI::dbDisconnect(con)
