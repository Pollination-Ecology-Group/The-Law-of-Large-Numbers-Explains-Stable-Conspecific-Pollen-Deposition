# Script to generate Summary Table for Discussion
# Calculates:
# 1. Network Metrics (H2', Evenness) from interaction_data_all_22_24
# 2. Deposition Metrics (Slope, Mean HP) from pollen_deposition
# 3. Plant Context (Succisa Abundance, Total Abundance) from plant_abundance_22_24

library(bipartite)
library(dplyr)
library(tidyr)
library(emmeans)
library(knitr)

# --- 1. Network Metrics ---

# Helper function to calculate network metrics for a specific year
calc_net_metrics <- function(year_val, data) {
    # Filter data for the year
    yr_data <- data %>% filter(year == year_val)

    # Check if data exists
    if (nrow(yr_data) == 0) {
        return(data.frame(Year = year_val, H2 = NA, Evenness = NA))
    }

    # Prepare matrix for bipartite (Plants x Pollinators)
    # Assuming columns: plant_species, pollinator_id (or pollinator_species), rate (or interaction)
    # Adjust column names if necessary based on your actual data structure

    # Detect pollinator column
    pol_col <- if ("pollinator_species" %in% names(yr_data)) "pollinator_species" else "pollinator_id"
    # Detect plant column
    plant_col <- if ("plant_species" %in% names(yr_data)) "plant_species" else "plant_id"
    # Detect interaction column
    int_col <- if ("rate" %in% names(yr_data)) "rate" else "interaction"

    web_matrix <- yr_data %>%
        select(all_of(plant_col), all_of(pol_col), all_of(int_col)) %>%
        pivot_wider(names_from = all_of(pol_col), values_from = all_of(int_col), values_fill = 0) %>%
        tibble::column_to_rownames(plant_col) %>%
        as.matrix()

    # Calculate indices
    # H2' (Specialization)
    h2 <- bipartite::H2fun(web_matrix)[1] # H2fun returns a vector, first element is H2'

    # Interaction Evenness
    # Note: networklevel returns a named vector
    evenness <- bipartite::networklevel(web_matrix, index = "interaction evenness")[1]

    return(data.frame(Year = year_val, H2 = h2, Evenness = evenness))
}

# Calculate for each year
net_metrics_list <- lapply(c(2022, 2023, 2024), calc_net_metrics, data = interaction_data_all_22_24)
network_summary <- do.call(rbind, net_metrics_list)


# --- 2. Deposition Metrics ---

# Fit the "Slope Showdown" model
# Model: sqrt(heterospecific_pollen) ~ conspecific_pollen * as.factor(year)
dep_model <- lm(sqrt(heterospecific_pollen) ~ conspecific_pollen * as.factor(year),
    data = pollen_deposition
)

# Calculate Slopes (Beta) for each year
item_trends <- emmeans::emtrends(dep_model, pairwise ~ year, var = "conspecific_pollen")
slopes_df <- as.data.frame(item_trends$emtrends) %>%
    mutate(Year = as.numeric(as.character(year))) %>%
    select(Year, Slope = conspecific_pollen.trend)

# Calculate Mean Heterospecific Pollen (HP) per year
# Using raw counts
hp_means <- pollen_deposition %>%
    group_by(year) %>%
    summarise(Mean_HP = mean(heterospecific_pollen, na.rm = TRUE), .groups = "drop") %>%
    mutate(Year = as.numeric(as.character(year)))


# --- 3. Plant Context ---

# Calculate Abundance metrics
# Assuming columns: year, species, abundance
# Adjust column names if necessary
plant_summary <- plant_abundance_22_24 %>%
    group_by(year) %>%
    summarise(
        # Check exact string for Succisa pratensis in your data (e.g., "Succisa pratensis", "Suc_pra")
        # Using 'mean' as requested for Succisa Abundance/Density
        Succisa_Abundance = mean(abundance[species == "Succisa pratensis" | species == "Suc_pra"], na.rm = TRUE),

        # Total Abundance (Community Floral Density)
        # Calculates sum of all abundance entries for the year.
        # IF data is per-plot, this sums across all plots and species (which might not be desired if N plots varies).
        # IF data is already aggregated (Year, Species, Mean_Abundance), this gives Community Floral Density correctly.
        Total_Abundance = sum(abundance, na.rm = TRUE),
        .groups = "drop"
    ) %>%
    mutate(Year = as.numeric(as.character(year)))


# --- 4. Combine and Output ---

# Merge all dataframes by Year
final_table <- network_summary %>%
    left_join(slopes_df, by = "Year") %>%
    left_join(hp_means, by = "Year") %>%
    left_join(plant_summary, by = "Year")

# Formatting
final_table_formatted <- final_table %>%
    mutate(
        H2 = round(H2, 2),
        Evenness = round(Evenness, 2),
        Slope = round(Slope, 2),
        Mean_HP = round(Mean_HP, 2),
        Succisa_Abundance = round(Succisa_Abundance, 2),
        Total_Abundance = round(Total_Abundance, 2)
    )

# Generate Table
kable(final_table_formatted,
    col.names = c("Year", "H2'", "Evenness", "Slope (β)", "Mean HP", "Succisa Abundance", "Total Abundance"),
    caption = "Table 4: Annual summary of plant-pollinator network topology, pollen deposition dynamics, and floral resource availability.",
    align = "c"
)
