library(bipartite)
library(dplyr)
library(tidyr)
devtools::load_all("local_packages/HanPolNet")

interaction_data_all_22_24 <- get_interaction_data(
    years = c(22, 23, 24), # only 3 years of data
    is_pollinator = TRUE, # only pollinators
    remove_zeros = TRUE, # remove interactions with 0 pollen
    standardize = TRUE # standardize interactions by sampling effort
)

print(head(interaction_data_all_22_24))

# Let's see what names exist
print(names(interaction_data_all_22_24))

year_val <- 2022
target_year <- if (year_val > 2000) year_val - 2000 else year_val
yr_data <- interaction_data_all_22_24 %>% filter(year == target_year | year == year_val)
print(nrow(yr_data))

pol_cols_possible <- c("pollinator_id", "pollinator_species", "pollinator")
pol_col <- pol_cols_possible[pol_cols_possible %in% names(yr_data)][1]
print(paste("pol_col:", pol_col))

plant_cols_possible <- c("plant_code", "plant_species", "plant_id", "plant")
plant_col <- plant_cols_possible[plant_cols_possible %in% names(yr_data)][1]
print(paste("plant_col:", plant_col))

int_cols_possible <- c("rate", "interaction_count", "interaction", "count")
int_col <- int_cols_possible[int_cols_possible %in% names(yr_data)][1]
print(paste("int_col:", int_col))
