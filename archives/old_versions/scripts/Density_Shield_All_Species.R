# ==============================================================================
# DENSITY SHIELD FOR ALL SPECIES
# ==============================================================================
# This script applies the Density Shield analysis (Dilution Effect and Interannual
# per-capita visitation shifts) to all plant species recorded in the network,
# generating a separate 2-panel plot for each species and saving them into a single PDF.

library(dplyr)
library(ggplot2)
library(patchwork)
library(HanPolNet)

message("Loading full datasets...")

# 0. Load data for all years and all species
interaction_data_all <- get_interaction_data(
    is_pollinator = TRUE,
    remove_zeros = TRUE,
    standardize = TRUE
)

plant_data_all <- get_plant_data(
    output = "standardized"
)

# Identify all valid plant species codes from the plant data
# First two cols are year and plot_id
all_plant_species <- setdiff(colnames(plant_data_all), c("year", "plot_id"))

# Filter to species that actually have interaction data to avoid empty plots
interacting_species <- unique(interaction_data_all$plant_code)
target_species <- intersect(all_plant_species, interacting_species)

message(sprintf("Found %d species with both abundance and interaction data.", length(target_species)))

# Create PDF output
output_file <- "Density_Shield_All_Species.pdf"
pdf(output_file, width = 12, height = 6)

for (species_code in target_species) {
    message(paste("Processing:", species_code))

    # 1. Calculate floral abundance per plot for all years for this species
    plant_abundance_per_plot_all <- plant_data_all %>%
        group_by(year, plot_id) %>%
        summarise(plot_abundance = sum(!!sym(species_code), na.rm = TRUE), .groups = "drop") %>%
        filter(!is.na(year)) %>%
        mutate(
            year_str = as.character(year),
            year = factor(ifelse(nchar(year_str) == 2, paste0("20", year_str), year_str)),
            plot_id = as.character(plot_id)
        )

    # 2. Calculate plot-level visitation for all years for this species
    visitation_per_plot_all <- interaction_data_all %>%
        filter(plant_code == species_code) %>%
        group_by(year, plot_id) %>%
        summarise(total_rate = sum(rate, na.rm = TRUE), .groups = "drop") %>%
        filter(!is.na(year)) %>%
        mutate(
            year_str = as.character(year),
            year = factor(ifelse(nchar(year_str) == 2, paste0("20", year_str), year_str)),
            plot_id = as.character(plot_id)
        )

    # 3. Calculate Per-Capita Visitation Rate (rate_per_plant)
    visitation_per_plant_all <- visitation_per_plot_all %>%
        left_join(plant_abundance_per_plot_all, by = c("year", "plot_id")) %>%
        mutate(
            rate_per_plant = ifelse(plot_abundance > 0, total_rate / plot_abundance, NA)
        ) %>%
        filter(!is.na(rate_per_plant) & !is.na(plot_abundance) & plot_abundance > 0)

    # Skip if there isn't enough data for a robust plot
    if (nrow(visitation_per_plant_all) < 3) {
        message(paste("  -> Skipped: Not enough data points for", species_code))
        next
    }

    # 5. Visualization: The Density Shield (2-Panel Figure)

    # Check if there's enough variation to fit a line
    has_variance <- length(unique(visitation_per_plant_all$plot_abundance)) > 1

    # Panel A: The general dilution rule (Scatterplot)
    p_dilution <- ggplot(visitation_per_plant_all, aes(x = plot_abundance, y = rate_per_plant)) +
        geom_point(aes(color = year), size = 3, alpha = 0.7) +
        scale_x_continuous(trans = "log1p") +
        scale_y_continuous(trans = "log1p") +
        theme_classic() +
        labs(
            title = paste("A) The Dilution Effect -", species_code),
            subtitle = "Higher floral density dilutes per-capita visitation",
            x = "Local Floral Abundance (log scale)",
            y = "Visits per Plant (log scale)",
            color = "Year"
        ) +
        scale_color_viridis_d(option = "plasma", end = 0.8)

    if (has_variance) {
        p_dilution <- p_dilution +
            geom_smooth(aes(color = year, group = year), method = "lm", se = FALSE, linewidth = 0.8, alpha = 0.5) +
            geom_smooth(method = "lm", color = "black", linetype = "dashed", se = TRUE)
    }

    # Panel B: The Anomaly (Boxplot)
    p_anomaly <- ggplot(visitation_per_plant_all, aes(x = year, y = rate_per_plant, fill = year)) +
        geom_boxplot(alpha = 0.8, outlier.shape = 21, outlier.size = 2) +
        theme_classic() +
        labs(
            title = paste("B) Interannual Shift in Per-Capita Rate -", species_code),
            subtitle = "Comparison across all surveyed years",
            x = "Year",
            y = "Visits per Plant"
        ) +
        scale_fill_viridis_d(option = "plasma", end = 0.8) +
        theme(legend.position = "none", axis.text.x = element_text(angle = 45, hjust = 1))

    # Combine panels
    final_shield_plot <- p_dilution + p_anomaly + plot_layout(widths = c(1.5, 1))

    # Print the plot to the PDF
    print(final_shield_plot)
}

dev.off()
message(sprintf("Output saved to %s", output_file))
