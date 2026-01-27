#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#| label: global-setup
#| include: false

# 1. Global Knitr Options
knitr::opts_chunk$set(echo = FALSE, warning = FALSE, message = FALSE, fig.path = "docs/images/")

# 2. Load Libraries
library(ggplot2)
library(dplyr)
library(tidyr)
library(nlme)
library(lme4)
library(stringr)
library(cowplot)
library(magick)
library(sf)
library(ggpubr)
library(emmeans)
library(patchwork)
library(knitr)
library(vegan)
library(gt)

# 3. Global Settings
theme_set(theme_bw())

# 4. Package Checks
# Install devtools if you haven't already
if (!require("devtools")) install.packages("devtools")

# Check if HanPolNet is installed and load it; if not, install from local source
if (!require("HanPolNet")) {
    devtools::install("local_packages/HanPolNet", upgrade = "never")
    library(HanPolNet)
}

# 5. Load and Prepare Data

# Pollen Load Data
pollen_load_guts_24 <- read.csv(file.path("data", "pollen_load_and_guts_2024_Succisa_pratensis.csv"))

# Pollen Deposition Data
data("pollen_deposition", package = "HanPolNet")

pollen_deposition <- pollen_deposition %>%
    mutate(
        # Create a unique plant_id using inflorescence_id + day
        # This correctly groups stigmas from the same plant/inflorescence on the same day for aggregation
        plant_id = paste(year, inflorescence_id, day, sep = "_")
    )

# Interaction Data
interaction_data_Succisa_22_24 <- get_interaction_data(
    years = c(22, 23, 24), # only 3 years of data
    plant_species = "Suc_pra", # only Succisa pratensis
    is_pollinator = TRUE, # only pollinators
    remove_zeros = TRUE, # remove interactions with 0 pollen
    standardize = TRUE # standardize interactions by sampling effort
)

# Interaction Data
interaction_data_all_22_24 <- get_interaction_data(
    years = c(22, 23, 24), # only 3 years of data
    is_pollinator = TRUE, # only pollinators
    remove_zeros = TRUE, # remove interactions with 0 pollen
    standardize = TRUE # standardize interactions by sampling effort
)

# Plant abundance data
plant_abundance_22_24 <- get_plant_data(
    years = c(22, 23, 24), # only 3 years of data
    output = "standardized" # standardize plant abundances: 
    # Sublot Counts are converted to a proportion by dividing by 64. A score of 64 becomes 1.0 (maximum frequency).
    # Stalk Counts are scaled relative to the maximum abundance observed for that specific species across the entire dataset. Each value is divided by that species’ global maximum, resulting in a scale where the highest observed count for that species is 1.0.
)

#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#| label: fig-plant-pollinator-panel
#| fig-cap: "A) Stigma of *Succisa pratensis* with several pollen morphotypes, B) Pollinator (*Eristalis* sp.) on flower of *Succisa pratensis*, see the pollen on pollinator body, C) Detail of anther with visible pollen grains of *Succisa pratensis*, D) Detail of stigma of *Succisa pratensis* with visible deposited pollen grains"
#| echo: false
#| warning: false
#| message: false
#| fig-width: 10
#| fig-height: 8

# Read and process images
# image_trim() removes the surrounding whitespace
img_A <- image_read("images/Blizna_Suc_pra_2.jpg") %>% image_trim()
img_B <- image_read("images/IMG_2335_small.jpg") %>% image_trim()
img_C <- image_read("images/P8197736.jpg") %>% image_trim() # Anther
img_D <- image_read("images/P8197678.jpg") %>% image_trim() # Stigma Detail

# Create plot objects with better scaling
# fitting the image into the draw area
p_A <- ggdraw() + draw_image(img_A, scale = 1)
p_B <- ggdraw() + draw_image(img_B, scale = 1)
p_C <- ggdraw() + draw_image(img_C, scale = 1)
p_D <- ggdraw() + draw_image(img_D, scale = 1)

# Arrange in a grid
# Using labels="AUTO" creates A, B, C, D automatically
# Adjusted label size and placement
plot_grid(p_A, p_B, p_C, p_D,
    labels = "AUTO",
    label_size = 18,
    label_fontface = "bold",
    ncol = 2,
    align = "hv",
    axis = "tb"
)
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#| label: fig-spatial-temporal-abundance
#| fig-cap: "Distribution and abundance of Succisa pratensis (2022-2024). A) Spatial distribution of plots with Succisa presence. B) Total abundance recorded per year. C) Differences in standardized visitation rates to Succisa pratensis across years (2022-2024)."
#| echo: true
#| warning: false
#| message: false
#| fig-height: 8

# --- PART A: MAP ---

# 1. Prepare Presence Data
succisa_presence <- plant_abundance %>%
    filter(year %in% c(22, 23, 24)) %>%
    select(year, plot_id, Suc_pra) %>%
    filter(Suc_pra > 0) %>%
    mutate(
        year_label = paste0("20", year),
        plot_id_join = as.character(as.integer(plot_id))
    )

# 2. Prepare Spatial Data
plots_sf <- hanpolnet_plots %>%
    mutate(
        plot_id_join = ifelse(grepl("^[0-9]+$", plot_id),
            as.character(as.integer(plot_id)),
            plot_id
        )
    )

# 3. Join
map_data <- succisa_presence %>%
    inner_join(plots_sf, by = "plot_id_join") %>%
    st_as_sf()

# 4. Create Map Plot Object
p_map <- ggplot() +
    geom_sf(data = plots_sf, color = "grey85", size = 1.5, shape = 1) +
    geom_sf(data = map_data, aes(color = year_label), size = 2) +
    facet_wrap(~year_label) +
    scale_color_viridis_d(begin = 0.2, end = 0.8, option = "D") +
    theme_minimal() +
    labs(
        title = "Succisa pratensis Presence",
        subtitle = "Plots with recorded abundance > 0",
        color = "Year"
    ) +
    theme(
        axis.text = element_blank(),
        axis.title = element_blank(),
        panel.grid = element_blank(),
        legend.position = "right"
    )

# --- PART B: ABUNDANCE ---

# 1. Summarize
abundance_summary <- plant_abundance %>%
    filter(year %in% c(22, 23, 24)) %>%
    group_by(year) %>%
    summarise(total_abundance = sum(Suc_pra, na.rm = TRUE)) %>%
    mutate(year_label = paste0("20", year))

# 2. Create Barplot Object
p_abundance <- ggplot(abundance_summary, aes(x = year_label, y = total_abundance, fill = year_label)) +
    geom_col(alpha = 0.8, width = 0.6) +
    labs(
        title = "Total Succisa pratensis Abundance",
        x = "Year",
        y = "Total Abundance\n (flowering stalks)"
    ) +
    scale_fill_viridis_d(begin = 0.2, end = 0.8, option = "D") +
    theme_minimal() +
    theme(legend.position = "none")


# Sum rates per plot to get total visitation intensity per plot
visitation_per_plot <- interaction_data_Succisa_22_24 %>%
    group_by(year, plot_id) %>%
    summarise(total_rate = sum(rate, na.rm = TRUE), .groups = "drop") %>%
    filter(!is.na(year)) %>%
    mutate(year = factor(paste0("20", year)))

# Plot
p_visitation <- ggplot(visitation_per_plot, aes(x = year, y = total_rate, fill = year)) +
    geom_boxplot(alpha = 0.6, outlier.shape = NA) +
    geom_jitter(width = 0.2, alpha = 0.5) +
    labs(
        title = "Visitation Rates per Plot",
        x = "Year",
        y = "Standardized Visitation Rate\n (interactions / visit)"
    ) +
    scale_fill_viridis_d(begin = 0.3, end = 0.7) +
    theme_minimal() +
    theme(legend.position = "none")

# --- COMBINE ---
ggarrange(p_map, p_abundance, p_visitation,
    ncol = 1,
    labels = c("A", "B", "C"),
    heights = c(1.5, 2, 2)
) # Give more height to the map
#
#
#
#
#
#
#
#| label: analysis-pollinator-composition
#| echo: true
#| warning: false
#| message: false
#| fig-cap: "Pollinator spectra composition on Succisa pratensis (2022-2024). Stacked bars show the proportion of standardized visitation rates for the most abundant species."

# 1. Aggregation
# Calculate total visitation rate per species per year
species_composition <- interaction_data_Succisa_22_24 %>%
    filter(!is.na(year)) %>% # Remove NA years
    group_by(year, pollinator_id) %>%
    summarise(total_rate = sum(rate, na.rm = TRUE), .groups = "drop") %>%
    group_by(year) %>%
    mutate(
        yearly_total = sum(total_rate),
        proportion = total_rate / yearly_total,
        year_label = paste0("20", year)
    )

# 2. Lump Rare Species
# Select top N most abundant species across all years to show individually
top_n_species <- 9
top_species_list <- species_composition %>%
    group_by(pollinator_id) %>%
    summarise(grand_total = sum(total_rate)) %>%
    arrange(desc(grand_total)) %>%
    slice_head(n = top_n_species) %>%
    pull(pollinator_id)

# Lump others
species_composition_grouped <- species_composition %>%
    mutate(
        species_label = ifelse(pollinator_id %in% top_species_list,
            pollinator_id,
            "Other"
        )
    ) %>%
    group_by(year_label, species_label) %>%
    summarise(proportion = sum(proportion), .groups = "drop")

# Reorder species for plotting (Other at bottom or top, others by abundance)
# We make "Other" the first level so it appears at one end of the stack
species_composition_grouped$species_label <- factor(
    species_composition_grouped$species_label,
    levels = c("Other", rev(top_species_list)) # Stack order
)

# Define Consistent Colors
pollinator_colors <- c(
    "Eristalis_tenax" = "#30123B", # Dark Purple
    "Eristalis_pertinax" = "#4675ED", # Blue
    "Eristalis_interrupta" = "#39568C", # Dark Blue
    "Eristalis_arbustorum" = "#42F4EB", # Cyan-ish
    "Eristalis_intricaria" = "#1E9C89", # Teal
    "Eristalis_similis" = "#248641", # Green
    "Eristalis_sp" = "#248641", # Green (fallback)
    "Helophilus_pendulus" = "#A2FC3C", # Light Green
    "Helophilus_trivittatus" = "#D9F121", # Yellow-Green
    "Helophilus_hybridus" = "#D9F121", # Yellow-Green
    "Myathropa_florea" = "#F9B614", # Yellow/Orange
    "Apis_mellifera" = "#F9B614", # Orange
    "Bombus_lapidarius" = "#EB520E", # Red-Orange
    "Sarcophaga_sp" = "#A42C17", # Dark Red
    "Zygena_sp" = "#D2204C", # Red/Pink
    "Sericomyia" = "#D2204C", # Red/Pink
    "Tachinidae" = "grey50",
    "Other" = "grey80"
)

# 3. Visualization
ggplot(species_composition_grouped, aes(x = year_label, y = proportion, fill = species_label)) +
    geom_col(width = 0.6, color = "white", size = 0.2) +
    scale_fill_manual(values = pollinator_colors, name = "Species") +
    labs(
        title = "Pollinator Spectra Composition",
        subtitle = "Proportion of Visitation Rates",
        x = "Year",
        y = "Proportion"
    ) +
    theme_minimal() +
    theme(
        legend.position = "right",
        legend.text = element_text(face = "italic")
    )
#
#
#
#
#
#
#
#
#
#| label: analysis-visitation-curve-fit
#| echo: true
#| code-fold: true

test_curve_shape <- function(year_data, year_label) {
    # 0. Data Aggregation (Mean per Plant)
    # Using the 'plant_id' we created earlier
    agg_data <- year_data %>%
        group_by(plant_id) %>%
        summarise(
            mean_HP = mean(heterospecific_pollen, na.rm = TRUE),
            mean_CP = mean(conspecific_pollen, na.rm = TRUE),
            .groups = "drop"
        )

    # 1. Fit Linear Model (Type 1) - Simple LM on Means
    fit_linear <- lm(mean_HP ~ mean_CP, data = agg_data)

    # 2. Fit Exponential Model (Type 3) - Simple NLS on Means
    fit_exp <- tryCatch(
        {
            nls(mean_HP ~ a * exp(b * mean_CP),
                data = agg_data,
                start = list(a = max(agg_data$mean_HP, na.rm = TRUE), b = -0.01)
            )
        },
        error = function(e) {
            # Fallback start values
            tryCatch(
                {
                    nls(mean_HP ~ a * exp(b * mean_CP),
                        data = agg_data,
                        start = list(a = mean(agg_data$mean_HP, na.rm = TRUE), b = -0.001)
                    )
                },
                error = function(e2) NULL
            )
        }
    )

    # 3. Compare AIC
    aic_lin <- AIC(fit_linear)
    aic_exp <- if (!is.null(fit_exp)) AIC(fit_exp) else NA

    return(data.frame(
        Year = year_label,
        Linear_AIC = round(aic_lin, 2),
        Exp_AIC = if (is.na(aic_exp)) NA else round(aic_exp, 2),
        Best_Fit = case_when(
            is.na(aic_exp) ~ "Linear (Type 1) [Exp Failed]",
            aic_exp < (aic_lin - 2) ~ "Exponential (Type 3)",
            TRUE ~ "Linear (Type 1)"
        )
    ))
}

# Run the test
results_2022 <- test_curve_shape(subset(pollen_deposition, year == 2022), "2022")
results_2023 <- test_curve_shape(subset(pollen_deposition, year == 2023), "2023")
results_2024 <- test_curve_shape(subset(pollen_deposition, year == 2024), "2024")

# Display Results
# Display Results
rbind(results_2022, results_2023, results_2024) %>%
    gt() %>%
    tab_header(title = "Model Comparison Results") %>%
    fmt_number(columns = c(Linear_AIC, Exp_AIC), decimals = 2) %>%
    cols_label(
        Year = "Year",
        Linear_AIC = "Linear AIC",
        Exp_AIC = "Exponential AIC",
        Best_Fit = "Best Fit Model"
    ) %>%
    tab_style(
        style = cell_text(weight = "bold"),
        locations = cells_column_labels()
    ) %>%
    tab_options(
        column_labels.background.color = "#F0F0F0",
        column_labels.font.weight = "bold",
        table.border.top.color = "black",
        table.border.top.width = px(2),
        table.border.bottom.color = "black",
        table.border.bottom.width = px(2),
        table_body.hlines.color = "#E5E5E5",
        data_row.padding = px(6)
    ) %>%
    tab_style(
        style = list(
            cell_text(color = "black", weight = "bold")
        ),
        locations = cells_column_labels()
    ) %>%
    opt_align_table_header(align = "left")

#
#
#
#
#
#
#
#| label: analysis-slope-comparison
#| echo: true
#| warning: false
#| message: false
#| fig-cap: "Relationship between Conspecific and Heterospecific pollen (Plant Means). Curves represent back-transformed fits from the sqrt-scale model."

# 1. Data Aggregation
aggregated_data <- pollen_deposition %>%
    group_by(year, plant_id) %>%
    summarise(
        mean_HP = mean(heterospecific_pollen, na.rm = TRUE),
        mean_CP = mean(conspecific_pollen, na.rm = TRUE),
        .groups = "drop"
    ) %>%
    filter(is.finite(mean_HP) & is.finite(mean_CP)) %>%
    filter(!is.na(year)) %>%
    mutate(Year = as.factor(year))

# 2. Model Fitting (Square Root Transformation)
# sqrt(mean_HP) ~ mean_CP * Year
fit_sqrt <- lm(sqrt(mean_HP) ~ mean_CP * Year, data = aggregated_data)

# 3. Model Results
# Type III ANOVA (if using car::Anova) or standard anova
# Type III ANOVA (if using car::Anova) or standard anova
anova_res <- anova(fit_sqrt)
anova_res %>%
    as.data.frame() %>%
    tibble::rownames_to_column(var = "Term") %>%
    gt() %>%
    tab_header(title = "Analysis of Variance: sqrt(HP) ~ CP * Year") %>%
    fmt_number(columns = c("Sum Sq", "Mean Sq", "F value", "Pr(>F)"), decimals = 3) %>%
    sub_small_vals(columns = "Pr(>F)", threshold = 0.001) %>%
    fmt_missing(columns = everything(), missing_text = "") %>%
    cols_label(Term = "Source") %>%
    tab_style(
        style = cell_text(weight = "bold"),
        locations = cells_body(
            rows = `Pr(>F)` < 0.05
        )
    ) %>%
    tab_style(
        style = cell_text(weight = "bold"),
        locations = cells_column_labels()
    ) %>%
    tab_options(
        column_labels.background.color = "#F0F0F0",
        column_labels.font.weight = "bold",
        table.border.top.color = "black",
        table.border.top.width = px(2),
        table.border.bottom.color = "black",
        table.border.bottom.width = px(2),
        table_body.hlines.color = "#E5E5E5",
        data_row.padding = px(6)
    ) %>%
    tab_style(
        style = list(
            cell_text(color = "black", weight = "bold")
        ),
        locations = cells_column_labels()
    ) %>%
    opt_align_table_header(align = "left")

# 4. Slope Comparisons (on Sqrt Scale)
slopes_sqrt <- emtrends(fit_sqrt, pairwise ~ Year, var = "mean_CP")

# Format Slope Estimates
# Format Slope Estimates
slope_est <- as.data.frame(slopes_sqrt$emtrends) %>%
    select(Year, Slope = mean_CP.trend, SE, df, lower.CL, upper.CL)

slope_est %>%
    gt() %>%
    tab_header(title = "Slope Estimates (Sqrt Scale)") %>%
    fmt_number(columns = c(Slope, SE, lower.CL, upper.CL), decimals = 4) %>%
    cols_label(
        lower.CL = "Lower CI",
        upper.CL = "Upper CI"
    ) %>%
    tab_style(
        style = cell_text(weight = "bold"),
        locations = cells_column_labels()
    ) %>%
    tab_options(
        column_labels.background.color = "#F0F0F0",
        column_labels.font.weight = "bold",
        table.border.top.color = "black",
        table.border.top.width = px(2),
        table.border.bottom.color = "black",
        table.border.bottom.width = px(2),
        table_body.hlines.color = "#E5E5E5",
        data_row.padding = px(6)
    ) %>%
    tab_style(
        style = list(
            cell_text(color = "black", weight = "bold")
        ),
        locations = cells_column_labels()
    ) %>%
    opt_align_table_header(align = "left")

# Format Pairwise Comparisons
# Format Pairwise Comparisons
slope_contrasts <- as.data.frame(slopes_sqrt$contrasts) %>%
    select(contrast, estimate, SE, df, t.ratio, p.value)

slope_contrasts %>%
    gt() %>%
    tab_header(title = "Pairwise Slope Comparisons") %>%
    fmt_number(columns = c(estimate, SE, t.ratio, p.value), decimals = 4) %>%
    sub_small_vals(columns = p.value, threshold = 0.001) %>%
    tab_style(
        style = cell_text(weight = "bold"),
        locations = cells_body(
            rows = p.value < 0.05
        )
    ) %>%
    tab_style(
        style = cell_text(weight = "bold"),
        locations = cells_column_labels()
    ) %>%
    tab_options(
        column_labels.background.color = "#F0F0F0",
        column_labels.font.weight = "bold",
        table.border.top.color = "black",
        table.border.top.width = px(2),
        table.border.bottom.color = "black",
        table.border.bottom.width = px(2),
        table_body.hlines.color = "#E5E5E5",
        data_row.padding = px(6)
    ) %>%
    tab_style(
        style = list(
            cell_text(color = "black", weight = "bold")
        ),
        locations = cells_column_labels()
    ) %>%
    opt_align_table_header(align = "left")

# 5. Visualization (Back-Transformed)

# Create prediction grid
# Range of CP for each year
pred_grid <- aggregated_data %>%
    group_by(Year) %>%
    do({
        seq_cp <- seq(min(.$mean_CP), max(.$mean_CP), length.out = 100)
        data.frame(mean_CP = seq_cp)
    }) %>%
    ungroup()

# Predict on Sqrt Scale with Confidence Intervals
preds <- predict(fit_sqrt, newdata = pred_grid, interval = "confidence")

# Bind and Back-Transform (Square)
pred_data <- cbind(pred_grid, preds) %>%
    mutate(
        mean_HP = fit^2, # Back-transform fit
        lwr_raw = lwr^2, # Back-transform lower CI
        upr_raw = upr^2 # Back-transform upper CI
    )

# Plot
ggplot(aggregated_data, aes(x = mean_CP, y = mean_HP, color = Year, fill = Year)) +
    # Observed Points
    geom_point(alpha = 0.5, size = 2) +
    # Confidence Ribbons (Back-transformed)
    geom_ribbon(data = pred_data, aes(ymin = lwr_raw, ymax = upr_raw), alpha = 0.2, color = NA) +
    # Fitted Lines (Back-transformed curves)
    geom_line(data = pred_data, size = 1) +
    labs(
        title = "Slope Showdown: CP vs HP",
        subtitle = "Model: sqrt(HP) ~ CP * Year (Back-transformed)",
        x = "Mean Conspecific Pollen (per plant)",
        y = "Mean Heterospecific Pollen (per plant)",
        color = "Year",
        fill = "Year"
    ) +
    scale_color_viridis_d(begin = 0.2, end = 0.8, option = "D") +
    scale_fill_viridis_d(begin = 0.2, end = 0.8, option = "D") +
    theme_minimal()
#
#
#
#
#
#
#
#| label: analysis-daily-stability
#| echo: true
#| warning: false
#| message: false
#| fig-cap: "Daily stability of pollen deposition network structure in 2024. A) Faceted by Day. B) Combined trends."

# 1. Data Prep
# Filter for 2024 and aggregate by plant_id (which is day-specific)
agg_data_2024 <- pollen_deposition %>%
    filter(year == 2024) %>%
    group_by(plant_id, day) %>%
    summarise(
        mean_HP = mean(heterospecific_pollen, na.rm = TRUE),
        mean_CP = mean(conspecific_pollen, na.rm = TRUE),
        .groups = "drop"
    )

# 2. Model Fitting
# Test if the slope (CP -> HP) varies by day (Interaction term)
fit_daily <- lm(mean_HP ~ mean_CP * as.factor(day), data = agg_data_2024)

# 3. Statistical Test
# ANOVA to check significance of the interaction term
anova_results <- anova(fit_daily)
print(anova_results)

# 4. Visualization
ggplot(agg_data_2024, aes(x = mean_CP, y = mean_HP)) +
    geom_point(alpha = 0.6, color = "darkblue") +
    geom_smooth(method = "lm", se = FALSE, color = "darkred", linetype = "dashed") +
    facet_wrap(~day) +
    labs(
        title = "Daily Stability of Pollen Deposition (2024)",
        subtitle = "Relationship between Conspecific and Heterospecific Pollen by Date",
        x = "Mean Conspecific Pollen (per plant)",
        y = "Mean Heterospecific Pollen (per plant)"
    ) +
    theme_minimal()
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#| label: analysis-variance-partitioning
#| echo: true
#| warning: false
#| message: false
#| fig-cap: "Variance Partitioning Results. A) Inter-Annual Stability (All Years). B) Intra-Annual Stability (2024 Only)."

# 1. Data Prep
# 1. Data Preparation
vca_data <- pollen_deposition %>%
    filter(!is.na(heterospecific_pollen) & !is.na(conspecific_pollen)) %>%
    mutate(
        # Response Variables
        sqrt_HP = sqrt(heterospecific_pollen),
        sqrt_CP = sqrt(conspecific_pollen),

        # Calculate Proportion HP (approximate normality with sqrt)
        total = heterospecific_pollen + conspecific_pollen,
        prop = ifelse(total > 0, heterospecific_pollen / total, 0),
        sqrt_Prop = sqrt(prop),

        # Factors
        year_fac = as.factor(year),
        date_fac = as.factor(paste(year, day, sep = "_")),
        plant_id = inflorescence_id # unique within year
    )

# 2. General Function for Two-Part VCA
run_twopart_vca <- function(data, variable_col, metric_label) {
    # Internal helper to extract variance
    extract_lmer_var <- function(model, name) {
        vc <- VarCorr(model)
        df <- as.data.frame(vc)

        # Ensure Residual is included
        if (!("Residual" %in% df$grp)) {
            sigma_sq <- attr(vc, "sc")^2
            df <- rbind(df, data.frame(grp = "Residual", var1 = NA, var2 = NA, vcov = sigma_sq, sdcor = attr(vc, "sc")))
        }

        # Calculate Percent
        total_var <- sum(df$vcov)
        df$percent <- (df$vcov / total_var) * 100
        df$Part <- name
        df$level <- dplyr::case_when(
            grepl("inflorescence", df$grp) ~ "Plant",
            grepl("plant_id", df$grp) ~ "Plant",
            df$grp == "year_fac" ~ "Year",
            df$grp == "date_fac" ~ "Date",
            df$grp == "Residual" ~ "Stigma",
            TRUE ~ "Other"
        )
        return(df[, c("Part", "level", "vcov", "sdcor", "percent")])
    }

    # Part 1: Inter-Annual (Global)
    f_inter <- as.formula(paste(variable_col, "~ 1 + (1 | year_fac / plant_id)"))
    m_inter <- lmer(f_inter, data = data)
    res_inter <- extract_lmer_var(m_inter, "Inter-Annual")

    # Part 2: Intra-Annual (2024 Only)
    data_24 <- filter(data, year == 2024)
    # Check if we have date variation in 2024
    f_intra <- as.formula(paste(variable_col, "~ 1 + (1 | date_fac / plant_id)"))
    m_intra <- lmer(f_intra, data = data_24)
    res_intra <- extract_lmer_var(m_intra, "Intra-Annual")

    # Combine
    combined <- rbind(res_inter, res_intra)
    combined$Metric <- metric_label
    return(combined)
}

# 3. Run for all 3 metrics (using Sqrt as validated in Supplement)
res_HP <- run_twopart_vca(vca_data, "sqrt_HP", "Heterospecific Pollen (Sq)")
res_CP <- run_twopart_vca(vca_data, "sqrt_CP", "Conspecific Pollen (Sq)")
res_Prop <- run_twopart_vca(vca_data, "sqrt_Prop", "Proportion HP (Sq)")

all_results <- rbind(res_HP, res_CP, res_Prop)

# Define factor levels
all_results$level <- factor(all_results$level, levels = c("Year", "Date", "Plant", "Stigma"))
all_results$Metric <- factor(all_results$Metric, levels = c("Heterospecific Pollen (Sq)", "Conspecific Pollen (Sq)", "Proportion HP (Sq)"))

# 4. Visualization (Percent only)
p_var <- ggplot(all_results, aes(x = Part, y = percent, fill = level)) +
    geom_bar(stat = "identity", width = 0.6) +
    facet_wrap(~Metric) +
    scale_fill_brewer(palette = "Set2") +
    geom_text(aes(label = ifelse(percent > 1.5, paste0(round(percent, 0), "%"), "")),
        position = position_stack(vjust = 0.5),
        size = 4,
        fontface = "bold",
        color = "black" # Black usually readable on Set2, or check individual colors
    ) +
    labs(
        title = "Variance Partitioning (Transformed Data)",
        y = "% of Total Variance",
        x = "",
        fill = "Variance Source"
    ) +
    theme_minimal() +
    theme(
        axis.text.x = element_text(face = "bold", angle = 0, hjust = 0.5, size = 11),
        strip.text = element_text(size = 12, face = "bold"),
        legend.position = "bottom"
    )

print(p_var)

# 5. GENERATE PUBLICATION TABLE (Table 2 for HP)
# We filter for Heterospecific Pollen (Sqrt) as that is the main story text
table_detailed <- all_results %>%
    filter(Metric == "Heterospecific Pollen (Sq)") %>%
    select(Part, level, vcov, sdcor, percent) %>%
    rename(
        Analysis = Part,
        Source = level,
        Variance = vcov,
        Std_Dev = sdcor,
        Percent_Total = percent
    ) %>%
    mutate(
        Variance = round(Variance, 2),
        Std_Dev = round(Std_Dev, 2),
        Percent_Total = paste0(round(Percent_Total, 1), "%")
    ) %>%
    arrange(Analysis, desc(Source))

# Print the detailed table
# Print the detailed table
table_detailed %>%
    gt() %>%
    tab_header(
        title = md("**Table 2**: Variance partitioning of square-root transformed heterospecific pollen deposition"),
        subtitle = "Results for Global (Inter-Annual) and 2024 (Intra-Annual) analyses."
    ) %>%
    cols_label(
        Analysis = "Analysis Scope",
        Source = "Variance Source",
        Variance = "Variance Component",
        Std_Dev = "SD",
        Percent_Total = "% Total"
    ) %>%
    tab_style(
        style = cell_text(weight = "bold"),
        locations = cells_column_labels()
    ) %>%
    tab_options(
        column_labels.background.color = "#F0F0F0",
        column_labels.font.weight = "bold",
        table.border.top.color = "black",
        table.border.top.width = px(2),
        table.border.bottom.color = "black",
        table.border.bottom.width = px(2),
        table_body.hlines.color = "#E5E5E5",
        data_row.padding = px(6)
    ) %>%
    tab_style(
        style = cell_borders(
            sides = "bottom",
            color = "gray",
            weight = px(1.5),
            style = "dashed"
        ),
        locations = cells_body(
            rows = Analysis == "Inter-Annual"
        )
    ) %>%
    tab_style(
        style = list(
            cell_text(color = "black", weight = "bold")
        ),
        locations = cells_column_labels()
    ) %>%
    opt_align_table_header(align = "left")
#
#
#
#
#
#
#
#
#
#| label: analysis-pollen-purity-combined
#| echo: true
#| warning: false
#| message: false
#| fig-height: 10
#| fig-cap: "Pollen Purity by Species. A) Proportion of Conspecific Pollen (CP) on pollinator bodies. B) Proportion of CP in pollinator guts."

# 1. Prepare Data (Body Loads)
pollen_loads <- pollen_load_guts_24 %>%
    filter(!is.na(suc_pra_load) & !is.na(other_pollen_load)) %>%
    mutate(
        Year = as.factor(year),
        Species = pollinator_species,
        Total_Load = suc_pra_load + other_pollen_load,
        Purity = suc_pra_load / Total_Load
    ) %>%
    filter(Total_Load > 0)

dominant_species <- names(which(table(pollen_loads$Species) >= 5))
pollen_loads_dom <- pollen_loads %>% filter(Species %in% dominant_species)

# 2. Prepare Data (Gut Content)
pollen_guts <- pollen_load_guts_24 %>%
    filter(!is.na(suc_pra_guts) & !is.na(other_pollen_guts)) %>%
    mutate(
        Year = as.factor(year),
        Species = pollinator_species,
        Total_Guts = suc_pra_guts + other_pollen_guts,
        Purity = suc_pra_guts / Total_Guts
    ) %>%
    filter(Total_Guts > 0)

# Filter for same dominant species for comparison (or their own dominant)
# Using same list ensures alignment if they define the community
pollen_guts_dom <- pollen_guts %>% filter(Species %in% dominant_species)

# 3. Visualization

# A) Body Purity Boxplot
p_body_purity <- ggplot(pollen_loads_dom, aes(x = Species, y = Purity, fill = Species)) +
    geom_boxplot(alpha = 0.7, outlier.shape = NA) +
    geom_jitter(width = 0.2, alpha = 0.5) +
    scale_fill_manual(values = pollinator_colors) +
    labs(
        title = "A. Body Pollen Purity",
        y = "Proportion Conspecific (Body)"
    ) +
    theme_minimal() +
    theme(
        axis.text.x = element_blank(), # Hide x labels for top plot
        axis.title.x = element_blank(),
        legend.position = "none"
    )

# B) Gut Purity Boxplot
p_gut_purity <- ggplot(pollen_guts_dom, aes(x = Species, y = Purity, fill = Species)) +
    geom_boxplot(alpha = 0.7, outlier.shape = NA) +
    geom_jitter(width = 0.2, alpha = 0.5) +
    scale_fill_manual(values = pollinator_colors) +
    labs(
        title = "B. Gut Pollen Purity",
        y = "Proportion Conspecific (Gut)"
    ) +
    theme_minimal() +
    theme(
        axis.text.x = element_text(angle = 45, hjust = 1, face = "italic"),
        legend.position = "none"
    )

# Combine
ggarrange(p_body_purity, p_gut_purity, ncol = 1, heights = c(1, 1.2), align = "v")
#
#
#
#
#
#
#
#| label: analysis-cv-comparison
#| echo: true
#| warning: false
#| message: false
#| fig-cap: "Coefficient of Variation (CV) of Conspecific (CP) and Heterospecific (HP) pollen counts across compartments."

# 1. Stigma CV
cv_stigma <- pollen_deposition %>%
  summarise(
    CP = sd(conspecific_pollen, na.rm=TRUE) / mean(conspecific_pollen, na.rm=TRUE) * 100,
    HP = sd(heterospecific_pollen, na.rm=TRUE) / mean(heterospecific_pollen, na.rm=TRUE) * 100
  ) %>%
  mutate(Compartment = "Stigma")

# 2. Body CV
# Ensure pollen_load_guts_24 is available (loaded in previous chunks or package)
if (!exists("pollen_load_guts_24")) {
    # Fallback to loading if not in env
     data("pollen_load_guts_24", package = "HanPolNet") 
}

cv_body <- pollen_load_guts_24 %>%
  summarise(
    CP = sd(suc_pra_load, na.rm=TRUE) / mean(suc_pra_load, na.rm=TRUE) * 100,
    HP = sd(other_pollen_load, na.rm=TRUE) / mean(other_pollen_load, na.rm=TRUE) * 100
  ) %>%
  mutate(Compartment = "Body")

# 3. Gut CV
cv_gut <- pollen_load_guts_24 %>%
  summarise(
    CP = sd(suc_pra_guts, na.rm=TRUE) / mean(suc_pra_guts, na.rm=TRUE) * 100,
    HP = sd(other_pollen_guts, na.rm=TRUE) / mean(other_pollen_guts, na.rm=TRUE) * 100
  ) %>%
  mutate(Compartment = "Gut")

# Combine and Reshape
cv_data <- bind_rows(cv_stigma, cv_body, cv_gut) %>%
  pivot_longer(cols = c(CP, HP), names_to = "Pollen_Type", values_to = "CV")

# Set Factor Levels
cv_data$Compartment <- factor(cv_data$Compartment, levels = c("Body", "Gut", "Stigma")) 

# Plot
ggplot(cv_data, aes(x = Compartment, y = CV, fill = Pollen_Type)) +
  geom_bar(stat = "identity", position = position_dodge(width = 0.9), color = "black", width = 0.8) +
  geom_text(aes(label = round(CV, 1)), position = position_dodge(width = 0.9), vjust = -0.5, size = 4) +
  scale_fill_manual(values = c("CP" = "#1ABC9C", "HP" = "#F1948A"), 
                    labels = c("CP" = "Conspecific", "HP" = "Heterospecific")) +
  labs(
    title = "Variability of Pollen Counts",
    y = "CV (%)",
    fill = "Pollen Type"
  ) +
  theme_minimal() +
  theme(
      axis.text.x = element_text(size = 12, face = "bold"),
      axis.text.y = element_text(size = 12),
      legend.position = "top"
  )
#
#
#
#
#
#
#
#
#
#
#
#
#| label: analysis-community-stability-evenness
#| echo: true
#| warning: false
#| message: false
#| fig-cap: "Community Stability and Structure. A) Temporal Stability (Morisita-Horn Similarity). B) Pollinator Evenness (J') per plot across years."
#| fig-height: 10
#| fig-width: 10

# --- Part 1: Community Similarity (Heatmap) ---

# 1. Aggregation for Stability Analysis
# Sum standardized rates per species per year, excluding NA years
community_matrix <- interaction_data_Succisa_22_24 %>%
    filter(!is.na(year)) %>%
    group_by(year, pollinator_id) %>%
    summarise(abundance = sum(rate, na.rm = TRUE), .groups = "drop") %>%
    pivot_wider(names_from = pollinator_id, values_from = abundance, values_fill = 0)

# Extract Matrix (Species columns only)
comm_mat <- as.matrix(community_matrix[, -1])
# Label clearly as 2022, 2023, 2024
rownames(comm_mat) <- paste0("20", community_matrix$year)

# 2. Calculate Morisita-Horn Dissimilarity
# vegdist returns dissimilarity (0 = identical, 1 = different)
mh_dist <- vegdist(comm_mat, method = "horn")

# Convert to Similarity (1 - Dissimilarity)
mh_sim <- 1 - as.matrix(mh_dist)

# 3. Visualization: Correlogram
# Reshape for ggplot
mh_long <- as.data.frame(mh_sim) %>%
    mutate(Year1 = rownames(.)) %>%
    pivot_longer(cols = -Year1, names_to = "Year2", values_to = "Similarity")

p_similarity <- ggplot(mh_long, aes(x = Year1, y = Year2, fill = Similarity)) +
    geom_tile(color = "white") +
    geom_text(aes(label = sprintf("%.2f", Similarity)), color = "black", size = 5) +
    scale_fill_gradient(low = "white", high = "#4675ED", limits = c(0, 1), name = "Similarity") +
    labs(
        title = "A. Community Similarity",
        subtitle = "Morisita-Horn Similarity Index",
        x = "",
        y = ""
    ) +
    theme_minimal() +
    theme(
        axis.text = element_text(size = 12, face = "bold"),
        panel.grid = element_blank()
    )

# --- Part 2: Pollinator Evenness (Boxplot) ---

# 1. Calculate Evenness (Alpha Diversity)
succisa_evenness <- calculate_pollinator_evenness(
    data = interaction_data_Succisa_22_24,
    group_by = c("year", "plot_id")
)

p_evenness <- ggplot(succisa_evenness, aes(x = as.factor(year), y = J, fill = as.factor(year))) +
    geom_boxplot(alpha = 0.6, outlier.shape = NA) +
    geom_jitter(width = 0.2, alpha = 0.5) +
    labs(
        title = "B. Pollinator Evenness (J')",
        subtitle = "Per plot",
        x = "Year",
        y = "Pielou's Evenness (J')"
    ) +
    theme_minimal() +
    theme(legend.position = "none")


# --- Part 3: Combine ---
if (!requireNamespace("ggpubr", quietly = TRUE)) install.packages("ggpubr")
ggpubr::ggarrange(p_similarity, p_evenness, ncol = 1, heights = c(1, 0.8))


#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
