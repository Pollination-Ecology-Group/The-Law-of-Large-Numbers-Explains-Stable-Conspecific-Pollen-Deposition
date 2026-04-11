library(bipartite)
library(dplyr)
library(tidyr)
devtools::load_all("local_packages/HanPolNet")

calc_net_metrics_debug <- function(year_val, data) {
    target_year <- if (year_val > 2000) year_val - 2000 else year_val
    yr_data <- data %>% filter(year == target_year | year == year_val)

    if (nrow(yr_data) == 0) {
        print("nrow is 0")
        return(NULL)
    }

    pol_cols_possible <- c("pollinator_id", "pollinator_species", "pollinator")
    pol_col <- pol_cols_possible[pol_cols_possible %in% names(yr_data)][1]

    plant_cols_possible <- c("plant_code", "plant_species", "plant_id", "plant")
    plant_col <- plant_cols_possible[plant_cols_possible %in% names(yr_data)][1]

    int_cols_possible <- c("rate", "interaction_count", "interaction", "count")
    int_col <- int_cols_possible[int_cols_possible %in% names(yr_data)][1]

    if (is.na(pol_col) | is.na(plant_col) | is.na(int_col)) {
        print("A col is NA")
        return(NULL)
    }

    web_matrix <- tryCatch(
        {
            mat <- yr_data %>%
                select(Plant = all_of(plant_col), Pollinator = all_of(pol_col), Interaction = all_of(int_col)) %>%
                mutate(Interaction = as.numeric(unlist(Interaction))) %>%
                group_by(Plant, Pollinator) %>%
                summarise(Interaction = sum(Interaction, na.rm = TRUE), .groups = "drop") %>%
                pivot_wider(names_from = Pollinator, values_from = Interaction, values_fill = 0) %>%
                tibble::column_to_rownames("Plant") %>%
                as.matrix()
            mat
        },
        error = function(e) {
            warning(paste("Error creating matrix for year", year_val, ":", e$message))
            return(NULL)
        }
    )

    if (is.null(web_matrix)) {
        print("web_matrix is NULL")
        return(NULL)
    }
    print("Matrix created! dimensions:")
    print(dim(web_matrix))

    h2 <- bipartite::H2fun(web_matrix, H2_integer = FALSE)[1]
    d_vals <- bipartite::specieslevel(web_matrix, index = "d", level = "lower")

    suc_names <- c("Suc_pra", "Succisa pratensis", "Succisa_pratensis")
    suc_row <- rownames(d_vals)[rownames(d_vals) %in% suc_names][1]

    print(paste("h2:", h2))
    print(paste("suc_row:", suc_row))

    return("Done")
}

interaction_data_all_22_24 <- get_interaction_data(
    years = c(22, 23, 24),
    is_pollinator = TRUE,
    remove_zeros = TRUE,
    standardize = TRUE
)

print("-------- 2022 --------")
calc_net_metrics_debug(2022, interaction_data_all_22_24)
print("-------- 2023 --------")
calc_net_metrics_debug(2023, interaction_data_all_22_24)
print("-------- 2024 --------")
calc_net_metrics_debug(2024, interaction_data_all_22_24)
