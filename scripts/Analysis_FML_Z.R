# ==============================================================================
# MASTER ANALYSIS SCRIPT: Linking Pollen Deposition Dynamics to Network Structure
# ==============================================================================
# Project: Succisa pratensis Pollination Ecology
# Author: Jakub Štenc
# Description: This script aggregates all statistical analyses and model diagnostics
#              from the manuscript and supplementary material for review.
#              All analyses are performed in the order they appear in the manuscript
#              and all plots concerning statistics are generated in this script,
#              however the final plots in the manuscript may have been edited in the
#              main quarto document or in another editor if necessary.
#              The script is organized into logical sections marked with "MARK: ".
#              Each section performs a specific analysis or diagnostic check.

# ==============================================================================

# ==============================================================================
## ---- global-setup
# MARK: 0. SETUP & LIBRARIES
# ==============================================================================
## Load required packages
packages <- c(
  "ggplot2", "dplyr", "tidyr", "nlme", "lme4", "stringr", "cowplot", 
  "magick", "sf", "ggpubr", "emmeans", "patchwork", "knitr", "vegan", 
  "gt", "dunn.test", "gridExtra", "lmerTest", "igraph", "overlapping", "bipartite",
  "OpenImageR", "iNEXT", "purrr", "sva", "flextable"
)

# Install missing packages automatically
new_packages <- packages[!(packages %in% installed.packages()[,"Package"])]
if(length(new_packages)) install.packages(new_packages)

# Load all packages
invisible(lapply(packages, library, character.only = TRUE))


# Data is now loaded directly from CSV/RDS files in the local 'data/' directory.
# The dependency on the HanPolNet package has been removed for standalone sharing.

# Set global theme
theme_set(theme_bw())

# ==============================================================================
# MARK: 1. DATA LOADING & PREPARATION
# ==============================================================================
message("Loading Data...")

# 1.1 Pollen Load & Gut Content Data
pollen_load_guts_24 <- read.csv(file.path("data", "pollen_load_and_guts_2024_Succisa_pratensis.csv"))

# 1.2 Pollen Deposition Data (Exported from HanPolNet)
pollen_deposition <- read.csv(file.path("data", "pollen_deposition.csv"))

# Pre-processing: Create unique plant_id grouping
pollen_deposition <- pollen_deposition %>%
    mutate(
        # Create a unique plant_id using inflorescence_id + day
        # This correctly groups stigmas from the same plant/inflorescence on the same day
        plant_id = paste(year, inflorescence_id, day, sep = "_")
    )

# Remove rows with NA values in conspecific_pollen or heterospecific_pollen
pollen_deposition <- subset(pollen_deposition, (!is.na(conspecific_pollen)) & (!is.na(heterospecific_pollen)))

# Define vca_data globally because fig-plots-2 requires it before fig-plots-3 runs in Quarto
vca_data <- pollen_deposition %>%
    filter(!is.na(heterospecific_pollen) & !is.na(conspecific_pollen)) %>%
    mutate(
        sqrt_HP = sqrt(heterospecific_pollen),
        sqrt_CP = sqrt(conspecific_pollen),
        year_fac = as.factor(year), 
        date_fac = as.factor(paste(year, day, sep = "_")), 
        plant_id = inflorescence_id 
    )

#summary(pollen_deposition)
#table(pollen_deposition$year)
#length(unique(pollen_deposition$plant_id))


# 1.3 Interaction Data (Succisa specific - Exported from HanPolNet)
interaction_data_Succisa_22_24 <- read.csv(file.path("data", "interaction_data_Succisa_22_24.csv"))

# 1.4 Interaction Data (Whole Community for context - Exported from HanPolNet)
interaction_data_all_22_24 <- read.csv(file.path("data", "interaction_data_all_22_24.csv"))
table(interaction_data_all_22_24$day, interaction_data_all_22_24$year)

# 1.5 Plant Abundance Data (Standardized - Exported from HanPolNet)
plant_abundance_22_24 <- read.csv(file.path("data", "plant_abundance_22_24.csv"))
# Note: Standardization details:
# Sublot Counts / 64 -> Proportion
# Stalk Counts / Max(Dataset) -> Relative Abundance


# 1.6 Single Visit Deposition (SVD) Data
SVD_Succisa_22_24 <- read.csv(file.path("data", "SVD_Succisa_pratensis.csv"))

table(SVD_Succisa_22_24$rok, SVD_Succisa_22_24$pollinator_species)


# 1.7 Plot Coordinates (HanPolNet -> RDS Format)
# Assuming 'hanpolnet_plots' comes from the package or is loaded in environment
if (file.exists(file.path("data", "hanpolnet_plots.rds"))) {
    hanpolnet_plots <- readRDS(file.path("data", "hanpolnet_plots.rds"))
}


# ==============================================================================
# SECTION S: SUPPLEMENTARY DIAGNOSTICS
# ==============================================================================
# Before running main analyses, we verify model assumptions and data distributions.

message("Running Supplementary Diagnostics...")

# ==============================================================================
# S1. Data Distribution Check
# ==============================================================================
# Checking the distribution of Heterospecific Pollen counts to justify transformation.

p_dist <- ggplot(pollen_deposition, aes(x = heterospecific_pollen)) +
    geom_histogram(binwidth = 5, fill = "darkgreen", color = "white", alpha = 0.7) +
    labs(
        title = "Distribution of Heterospecific Pollen",
        subtitle = "Raw counts per stigma",
        x = "Heterospecific Pollen Count",
        y = "Frequency"
    ) +
    theme_minimal()
# print(p_dist)


p_dist2 <- ggplot(pollen_deposition, aes(x = conspecific_pollen)) +
    geom_histogram(binwidth = 5, fill = "darkgreen", color = "white", alpha = 0.7) +
    labs(
        title = "Distribution of Conspecific Pollen",
        subtitle = "Raw counts per stigma",
        x = "Conspecific Pollen Count",
        y = "Frequency"
    ) +
    theme_minimal()
# print(p_dist2)

# ==============================================================================
# MARK: S2. Variance Partitioning Model Diagnostics (Transformation Check)
# ==============================================================================
# Variance Components Analysis (VCA) is used to partition the total variability
# in pollen deposition into hierarchical levels (e.g., Year vs. Plant vs. Stigma level).
# This helps us identify the exact scale at which pollen transfer is most unpredictable.
#
# Because pollen deposition is count data, it frequently exhibits right-skewness
# and heteroscedasticity (variance increases with the mean). Linear Mixed Models (LMMs),
# which we use for VCA, strictly assume that residuals are normally distributed and
# have constant variance (homoscedasticity).
#
# To satisfy these assumptions, we visually compare three states of the data:
#  1. Raw: The original counts (often violates assumptions).
#  2. Log (log1p): Squashes large extreme values, standard for overdispersed counts.
#  3. Sqrt (sqrt): The theoretical variance-stabilizing transformation for Poisson-like
#     data, where variance naturally scales linearly with the mean.
#


# The generated diagnostic plots (Residuals vs Fitted, and Residual Histograms)
# allow us to select the transformation that provides the best model fit before
# running the formal VCA in Section 2.5.

# This will go to the Supplementary material

# Prepare data for VCA diagnostics
vca_diag_data <- pollen_deposition %>%
    filter(!is.na(heterospecific_pollen) & !is.na(conspecific_pollen)) %>%
    mutate(
        year_fac = as.factor(year),
        plant_id = inflorescence_id,
        total_pollen = heterospecific_pollen + conspecific_pollen,
        prop_HP = ifelse(total_pollen > 0, heterospecific_pollen / total_pollen, 0)
    )

# Helper function for diagnostics visualization
run_transformation_diagnostics <- function(data, variable_name, title_prefix) {
    y <- data[[variable_name]]
    y_log <- log1p(y)
    y_sqrt <- sqrt(y)

    # Fit Models
    m_raw <- lmer(y ~ 1 + (1 | year_fac / plant_id), data = data)
    m_log <- lmer(y_log ~ 1 + (1 | year_fac / plant_id), data = data)
    m_sqrt <- lmer(y_sqrt ~ 1 + (1 | year_fac / plant_id), data = data)

    # Plotting Helper
    make_plots <- function(model, suffix) {
        df <- data.frame(Fitted = fitted(model), Residuals = resid(model))

        p_hist <- ggplot(df, aes(x = Residuals)) +
            geom_histogram(bins = 30, fill = "steelblue", color = "white", alpha = 0.7) +
            labs(title = paste("Hist:", suffix), x = "", y = "Freq") +
            theme_minimal()

        p_res <- ggplot(df, aes(x = Fitted, y = Residuals)) +
            geom_point(alpha = 0.3) +
            geom_hline(yintercept = 0, color = "red", linetype = "dashed") +
            labs(title = paste("Res vs Fit:", suffix), x = "Fitted", y = "Res") +
            theme_minimal()
        return(list(p_hist, p_res))
    }

    pl_raw <- make_plots(m_raw, "Raw")
    pl_log <- make_plots(m_log, "Log")
    pl_sqrt <- make_plots(m_sqrt, "Sqrt")

    # Plot Grid
    grid.arrange(
        pl_raw[[1]], pl_log[[1]], pl_sqrt[[1]],
        pl_raw[[2]], pl_log[[2]], pl_sqrt[[2]],
        nrow = 2, ncol = 3,
        top = title_prefix
    )
}

# Run Checks
message("Running VCA Diagnostics (Outputs plots)...")
# Heterospecific Pollen
run_transformation_diagnostics(vca_diag_data, "heterospecific_pollen", "S1.1 Heterospecific Pollen")
# Conspecific Pollen
run_transformation_diagnostics(vca_diag_data, "conspecific_pollen", "S1.2 Conspecific Pollen")



# ==============================================================================
# MARK: S3. Model Selection Diagnostics (Linear vs Exponential)
# ==============================================================================
# Diagnosing the fit of Linear vs Exponential models for the CP-HP relationship.

# Prepare Aggregated Data (Mean per Plant)
model_selection_data <- pollen_deposition %>%
    group_by(year, plant_id) %>% # plant_id is already unique (year_inflo_day)
    summarise(
        mean_HP = mean(heterospecific_pollen, na.rm = TRUE),
        mean_CP = mean(conspecific_pollen, na.rm = TRUE),
        .groups = "drop"
    ) %>%
    filter(is.finite(mean_HP) & is.finite(mean_CP))

get_year_diagnostics <- function(yr) {
    dat <- subset(model_selection_data, year == yr)

    # Fit Linear
    m_lin <- lm(mean_HP ~ mean_CP, data = dat)
    aic_lin <- AIC(m_lin)

    # Fit Exponential
    m_exp <- tryCatch(
        nls(mean_HP ~ a * exp(b * mean_CP),
            data = dat,
            start = list(a = max(dat$mean_HP, na.rm = TRUE), b = -0.01)
        ),
        error = function(e) NULL
    )
    # Fallback start values if needed
    if (is.null(m_exp)) {
        m_exp <- tryCatch(
            nls(mean_HP ~ a * exp(b * mean_CP),
                data = dat,
                start = list(a = mean(dat$mean_HP, na.rm = TRUE), b = -0.001)
            ),
            error = function(e) NULL
        )
    }

    aic_exp <- if (!is.null(m_exp)) AIC(m_exp) else Inf

    # Select Best Model based on AIC (Delta > 2 preference for Expl, otherwise Parsimony)
    if (aic_exp < (aic_lin - 2)) {
        best_model <- m_exp
        type <- "Exponential (Type 3)"
    } else {
        best_model <- m_lin
        type <- "Linear (Type 1)"
    }

    resids <- resid(best_model)
    fitted_vals <- fitted(best_model)

    # Plot
    title_res <- paste0(yr, ": ", type, "\nResid vs Fitted")
    title_qq <- paste0(yr, ": Q-Q Plot")

    p_res <- ggplot(data.frame(F = fitted_vals, R = resids), aes(x = F, y = R)) +
        geom_point(alpha = 0.6) +
        geom_hline(yintercept = 0, color = "red", linetype = "dashed") +
        labs(title = title_res, x = "Fitted", y = "Residuals") +
        theme_minimal()

    p_qq <- ggplot(data.frame(R = resids), aes(sample = R)) +
        stat_qq() +
        stat_qq_line(color = "red") +
        labs(title = title_qq, x = "Theoretical", y = "Sample") +
        theme_minimal()

    return(list(p_res, p_qq))
}

message("Running Model Selection Diagnostics...")
plots_22 <- get_year_diagnostics(2022)
plots_23 <- get_year_diagnostics(2023)
plots_24 <- get_year_diagnostics(2024)

grid.arrange(
    plots_22[[1]], plots_22[[2]],
    plots_23[[1]], plots_23[[2]],
    plots_24[[1]], plots_24[[2]],
    ncol = 2, top = "S3. CP-HP Model Selection Diagnostics"
)


# ==============================================================================
# S4. Slope Comparison Diagnostics
# ==============================================================================
# In Section 2.3, we formally test if the rate of Heterospecific Pollen (HP)
# accumulation changes across years. We parameterize this as a Linear Model
# testing how HP scales with Conspecific Pollen (CP), interacting with Year.
#
# Based on the VCA diagnostics in S2, we apply a Square-Root transformation to HP
# prior to fitting this linear model. This step visually validates the assumptions
# of that specific LM (lm(sqrt(HP) ~ CP * Year)).
#
# By examining the Residuals vs Fitted plot and the Normal Q-Q plot, reviewers
# can confirm that the square-root transformation successfully achieves
# relatively constant variance and normally distributed residuals, justifying
# the subsequent extraction and comparison of the slope estimates using emmeans.

model_data_agg <- model_selection_data %>% # Reuse aggregated data
    filter(!is.na(year)) %>%
    mutate(Year = as.factor(year))

fit_sqrt_supp <- lm(sqrt(mean_HP) ~ mean_CP * Year, data = model_data_agg)

message("Running Slope Comparison Diagnostics...")
par(mfrow = c(1, 2))
plot(fit_sqrt_supp, which = 1, main = "A. Residuals vs Fitted")
plot(fit_sqrt_supp, which = 2, main = "B. Normal Q-Q")
par(mfrow = c(1, 1))

message("Diagnostics Complete. Proceeding to Main Analyses.")


# ==============================================================================
# MARK: 2. MAIN ANALYSES
# ==============================================================================

# ==============================================================================
# 2.0 Succisa pratensis Abundance and Presence
# This section evaluates the spatial distribution and abundance of Succisa
# pratensis across the study area. We first map the presence of the species
# across plots for each year (Part A) and then analyze the variation in
# flower head density (Part B) to characterize the floral resource landscape.

# ==============================================================================

# === PART A: PRESENCE ===

# 1. Prepare Presence Data
succisa_presence <- plant_abundance_22_24 %>%
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
            as.character(suppressWarnings(as.integer(as.character(plot_id)))),
            as.character(plot_id)
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
    scale_color_viridis_d(begin = 0.2, end = 0.8, option = "magma") +
    theme_classic() +
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

# === PART B: ABUNDANCE ===

# 1. Summarize
abundance_summary <- plant_abundance_22_24 %>%
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
    scale_fill_viridis_d(begin = 0.2, end = 0.8, option = "magma") +
    theme_classic() +
    theme(legend.position = "none")

# === PART C: VISITATION ===

# Sum rates per plot to get total visitation intensity per plot
visitation_per_plot <- interaction_data_Succisa_22_24 %>%
    group_by(year, plot_id) %>%
    summarise(total_rate = sum(rate, na.rm = TRUE), .groups = "drop") %>%
    filter(!is.na(year)) %>%
    mutate(year = factor(paste0("20", year)))


# === PART D: VISITATION PER PLANT ABUNDANCE ===
plant_abundance_per_plot <- plant_abundance_22_24 %>%
    group_by(year, plot_id) %>%
    summarise(plot_abundance = sum(Suc_pra, na.rm = TRUE), .groups = "drop") %>%
    filter(!is.na(year)) %>%
    mutate(
        year = factor(paste0("20", year)),
        plot_id = as.character(plot_id)
    )

visitation_per_plant <- visitation_per_plot %>%
    left_join(plant_abundance_per_plot, by = c("year", "plot_id")) %>%
    mutate(rate_per_plant = ifelse(plot_abundance > 0, total_rate / plot_abundance, NA))

# --- STATISTICAL TESTS (run first so results can be used in plot subtitles) ---
kw_plot <- kruskal.test(total_rate ~ year, data = visitation_per_plot)
kw_plot_label <- sprintf(
    "Kruskal-Wallis: \u03c7\u00b2_{%d} = %.2f, p %s",
    kw_plot$parameter, kw_plot$statistic,
    ifelse(kw_plot$p.value < 0.001, "< 0.001", sprintf("= %.3f", kw_plot$p.value))
)

kw_plant <- kruskal.test(rate_per_plant ~ year, data = visitation_per_plant)
kw_plant_label <- sprintf(
    "Kruskal-Wallis: \u03c7\u00b2_{%d} = %.2f, p %s",
    kw_plant$parameter, kw_plant$statistic,
    ifelse(kw_plant$p.value < 0.001, "< 0.001", sprintf("= %.3f", kw_plant$p.value))
)

if (kw_plot$p.value < 0.05) {
    # cat("\nPairwise Differences (Per Plot):\n")
    dunn.test(visitation_per_plot$total_rate, visitation_per_plot$year, method = "bh")
}

if (kw_plant$p.value < 0.05) {
    # cat("\nPairwise Differences (Per Plant):\n")
    dunn.test(visitation_per_plant$rate_per_plant, visitation_per_plant$year, method = "bh")
}

# Plot B
p_visitation <- ggplot(visitation_per_plot, aes(x = year, y = total_rate, fill = year)) +
    geom_boxplot(alpha = 0.6, outlier.shape = NA) +
    geom_jitter(width = 0.2, alpha = 0.5) +
    labs(
        title = "Visitation Rates per Plot",
        subtitle = kw_plot_label,
        x = "Year",
        y = "Standardized Visitation Rate\n (interactions/sampling effort)"
    ) +
    scale_fill_viridis_d(begin = 0.3, end = 0.7, option = "magma") +
    theme_classic() +
    theme(
        legend.position = "none",
        plot.subtitle = element_text(size = 9, color = "gray30")
    )

# Plot C
p_visitation_per_plant <- ggplot(visitation_per_plant, aes(x = year, y = rate_per_plant, fill = year)) +
    geom_boxplot(alpha = 0.6, outlier.shape = NA) +
    geom_jitter(width = 0.2, alpha = 0.5) +
    labs(
        title = "Visitation Rates per Plant",
        subtitle = kw_plant_label,
        x = "Year",
        y = "Standardized Visitation Rate\n (interactions/sampling effort/plant abundance)"
    ) +
    scale_fill_viridis_d(begin = 0.3, end = 0.7, option = "magma") +
    theme_classic() +
    theme(
        legend.position = "none",
        plot.subtitle = element_text(size = 9, color = "gray30")
    )

# --- COMBINE ---
library(cowplot)
library(magick)
img_plant <- image_read("images/plant.png")
img_pollinator <- image_read("images/Pollinator.png")

# Add images above the first bar (approx x = 0.17) but below the text (y = 0.55)
p_abundance_w_img <- ggdraw(p_abundance) + 
  draw_image(img_plant, x = 0.17, y = 0.55, width = 0.10, height = 0.20)

p_visitation_w_img <- ggdraw(p_visitation) + 
  draw_image(img_pollinator, x = 0.17, y = 0.55, width = 0.10, height = 0.20)

p_visitation_per_plant_w_img <- ggdraw(p_visitation_per_plant) + 
  draw_image(img_plant, x = 0.14, y = 0.55, width = 0.08, height = 0.16) +
  draw_image(img_pollinator, x = 0.20, y = 0.55, width = 0.08, height = 0.16)

spatial_temporal_plot <- ggpubr::ggarrange(
    p_abundance_w_img, p_visitation_w_img, p_visitation_per_plant_w_img,
    ncol = 1,
    labels = c("A", "B", "C"),
    heights = c(2, 2, 2)
)
# print(spatial_temporal_plot)


# ==============================================================================
# MARK: 2.1 Pollinator Spectra Composition (Analysis of Stability)
# ==============================================================================
# This analysis evaluates the relative abundance (visitation rate) of different
# pollinator taxa visiting the focal plant across the three years.
#
# Ecological Relevance: Before attributing changes in pollen deposition to floral
# density or single-visit stochasticity, we must confirm whether the core
# plant-pollinator network remains broadly stable over time. If the pollinator
# community composition remains consistent (e.g., heavily dominated by Eristalis),
# then any observed buffering in conspecific pollen receipt is likely driven by
# mechanisms like visitation redundancy rather than a complete turnover or
# collapse of the local insect assemblage.
#
# Process: We aggregate the total standard visitation rate for each pollinator
# taxon per year, lump the rare, low-frequency taxa into a unified "Other"
# category to reduce noise, and calculate the proportional composition to allow
# for year-to-year comparisons of the main interacting guild.
#message("Analyzing Pollinator Spectra...")

# Aggregate visitation rates
species_composition <- interaction_data_Succisa_22_24 %>%
    filter(!is.na(year)) %>%
    group_by(year, pollinator_id) %>%
    summarise(total_rate = sum(rate, na.rm = TRUE), .groups = "drop") %>%
    group_by(year) %>%
    mutate(
        yearly_total = sum(total_rate),
        proportion = total_rate / yearly_total,
        year_label = paste0("20", year)
    )

# Prepare for Visualization (Lump rare species)
top_n_species <- 9
top_species_list <- species_composition %>%
    group_by(pollinator_id) %>%
    summarise(grand_total = sum(total_rate)) %>%
    arrange(desc(grand_total)) %>%
    slice_head(n = top_n_species) %>%
    pull(pollinator_id)

species_grouped <- species_composition %>%
    mutate(species_label = ifelse(pollinator_id %in% top_species_list, pollinator_id, "Other")) %>%
    group_by(year_label, species_label) %>%
    summarise(proportion = sum(proportion), .groups = "drop")



species_composition <- interaction_data_Succisa_22_24 %>%
    filter(!is.na(year)) %>%
    group_by(year, pollinator_id) %>%
    summarise(total_rate = sum(rate, na.rm = TRUE), .groups = "drop") %>%
    group_by(year) %>%
    mutate(
        yearly_total = sum(total_rate),
        proportion = total_rate / yearly_total,
        year_label = paste0("20", year)
    )

top_n_species <- 9
top_species_list <- species_composition %>%
    group_by(pollinator_id) %>%
    summarise(grand_total = sum(total_rate)) %>%
    arrange(desc(grand_total)) %>%
    slice_head(n = top_n_species) %>%
    pull(pollinator_id)

species_composition_grouped <- species_composition %>%
    mutate(
        species_label = ifelse(pollinator_id %in% top_species_list,
            pollinator_id,
            "Other"
        )
    ) %>%
    group_by(year_label, species_label) %>%
    summarise(proportion = sum(proportion), .groups = "drop")

species_composition_grouped$species_label <- factor(
    species_composition_grouped$species_label,
    levels = c("Other", rev(top_species_list))
)

pollinator_colors <- c(
    "Eristalis_tenax" = "#30123B", "Eristalis_pertinax" = "#4675ED",
    "Eristalis_interrupta" = "#39568C", "Eristalis_arbustorum" = "#42F4EB",
    "Eristalis_intricaria" = "#1E9C89", "Eristalis_similis" = "#248641",
    "Eristalis_sp" = "#248641", "Helophilus_pendulus" = "#A2FC3C",
    "Helophilus_trivittatus" = "#D9F121", "Helophilus_hybridus" = "#D9F121",
    "Myathropa_florea" = "#F9B614", "Apis_mellifera" = "#F9B614",
    "Bombus_lapidarius" = "#EB520E", "Sarcophaga_sp" = "#A42C17",
    "Zygena_sp" = "#D2204C", "Sericomyia" = "#D2204C",
    "Tachinidae" = "grey50", "Other" = "grey80"
)

p_composition <- ggplot(species_composition_grouped, aes(x = year_label, y = proportion, fill = species_label)) +
    geom_col(width = 0.6, color = "white", linewidth = 0.2) +
    scale_fill_manual(values = pollinator_colors, name = "<img src='images/Pollinator.png' width='50'/><br>Species") +
    labs(
        title = "A. Pollinator Spectra Composition",
        subtitle = "Proportion of Visitation Rates",
        x = "Year",
        y = "Proportion"
    ) +
    theme_classic() +
    theme(
        legend.position = "right",
        legend.title = ggtext::element_markdown(halign = 0.5),
        legend.text = element_text(face = "italic")
    )

# === Part 1: Community Similarity (Heatmap) ===

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

# 3. Visualization: Correlogram (Styled Heatmap)
# Mask upper triangle to create a lower-triangular plot
mh_sim[upper.tri(mh_sim)] <- NA

# Reshape for ggplot
mh_long <- as.data.frame(mh_sim) %>%
    mutate(Year1 = rownames(.)) %>%
    pivot_longer(cols = -Year1, names_to = "Year2", values_to = "Similarity") %>%
    filter(!is.na(Similarity))

p_similarity <- ggplot(mh_long, aes(x = Year2, y = Year1, fill = Similarity)) +
    geom_tile(color = "white") +
    geom_text(aes(label = sprintf("%.2f", Similarity)), color = "black", size = 5) +
    scale_fill_viridis_c(
        option = "mako", begin = 0.1, end = 0.9, limit = c(0, 1), name = "<img src='images/Pollinator.png' width='50'/><br>Similarity"
    ) +
    # Reverse Y axis to put first year on top (Matrix layout)
    scale_y_discrete(limits = rev) +
    labs(
        title = "C. Pollinator Composition Similarity",
        subtitle = "Morisita-Horn Similarity Index",
        x = "",
        y = ""
    ) +
    theme_classic() +
    theme(
        axis.text = element_text(size = 12, face = "bold"),
        panel.grid = element_blank(),
        legend.position = "right",
        legend.title = ggtext::element_markdown(halign = 0.5)
    )

# === Part 2: Floral Community Similarity (Heatmap) ===

# 1. Aggregation for Stability Analysis
# Ensure proper year format
plant_matrix_prep <- plant_abundance_22_24 %>%
    mutate(year = as.numeric(as.character(year))) %>%
    mutate(year = if_else(year < 100, year + 2000, year)) %>%
    # Sum abundance per species per year (across plots)
    # The abundance data is already standardized per species/plot, so summing gives a community-level profile
    pivot_longer(cols = -c(year, plot_id), names_to = "Species", values_to = "Abundance") %>%
    group_by(year, Species) %>%
    summarise(total_abundance = sum(Abundance, na.rm = TRUE), .groups = "drop") %>%
    pivot_wider(names_from = Species, values_from = total_abundance, values_fill = 0)

# Extract Matrix
if (nrow(plant_matrix_prep) > 0) {
    comm_mat_plant <- as.matrix(plant_matrix_prep[, -1])
    rownames(comm_mat_plant) <- as.character(plant_matrix_prep$year)

    # 2. Calculate Morisita-Horn
    mh_dist_plant <- vegdist(comm_mat_plant, method = "horn")
    mh_sim_plant <- 1 - as.matrix(mh_dist_plant)

    # 3. Visualization
    mh_sim_plant[upper.tri(mh_sim_plant)] <- NA

    mh_long_plant <- as.data.frame(mh_sim_plant) %>%
        mutate(Year1 = rownames(.)) %>%
        pivot_longer(cols = -Year1, names_to = "Year2", values_to = "Similarity") %>%
        filter(!is.na(Similarity))

    p_plant_similarity <- ggplot(mh_long_plant, aes(x = Year2, y = Year1, fill = Similarity)) +
        geom_tile(color = "white") +
        geom_text(aes(label = sprintf("%.2f", Similarity)), color = "black", size = 5) +
        scale_fill_viridis_c(
            option = "viridis", begin = 0.1, end = 0.9, limit = c(0, 1), name = "<img src='images/plant.png' width='40'/><br>Similarity"
        ) +
        scale_y_discrete(limits = rev) +
        labs(
            title = "D. Floral Community Similarity",
            subtitle = "Morisita-Horn Similarity Index",
            x = "",
            y = ""
        ) +
        theme_classic() +
        theme(
            axis.text = element_text(size = 12, face = "bold"),
            panel.grid = element_blank(),
            legend.position = "right",
            legend.title = ggtext::element_markdown(halign = 0.5)
        )
} else {
    p_plant_similarity <- ggplot() +
        labs(title = "No Plant Data Available")
}

# === Part 3: Floral Spectra Composition ===
plant_composition_grouped <- plant_matrix_prep %>%
    pivot_longer(cols = -year, names_to = "Species", values_to = "total_abundance") %>%
    filter(total_abundance > 0) %>%
    group_by(year) %>%
    mutate(
        yearly_total = sum(total_abundance),
        proportion = total_abundance / yearly_total,
        year_label = as.character(year)
    ) %>%
    ungroup()

top_n_plants <- 9
top_plant_list <- plant_composition_grouped %>%
    group_by(Species) %>%
    summarise(grand_total = sum(total_abundance)) %>%
    arrange(desc(grand_total)) %>%
    slice_head(n = top_n_plants) %>%
    pull(Species)

plant_composition_grouped <- plant_composition_grouped %>%
    mutate(species_label = ifelse(Species %in% top_plant_list, Species, "Other")) %>%
    group_by(year_label, species_label) %>%
    summarise(proportion = sum(proportion), .groups = "drop")

plant_composition_grouped$species_label <- factor(
    plant_composition_grouped$species_label,
    levels = c("Other", rev(top_plant_list))
)

p_plant_composition <- ggplot(plant_composition_grouped, aes(x = year_label, y = proportion, fill = species_label)) +
    geom_col(width = 0.6, color = "white", linewidth = 0.2) +
    scale_fill_viridis_d(option = "H", direction = 1, name = "<img src='images/plant.png' width='40'/><br>Species") +
    labs(
        title = "B. Floral Spectra Composition",
        subtitle = "Proportion of Plant Abundance",
        x = "Year",
        y = "Proportion"
    ) +
    theme_classic() +
    theme(
        legend.position = "right",
        legend.title = ggtext::element_markdown(halign = 0.5),
        legend.text = element_text(face = "italic")
    )


if (!requireNamespace("ggpubr", quietly = TRUE)) install.packages("ggpubr")

# Combine in Layout
# Row 1: A (Pollinator Spectra) | B (Floral Spectra)
# Row 2: C (Pollinator Sim) | D (Floral Sim)
row1 <- ggpubr::ggarrange(p_composition, p_plant_composition, ncol = 2, labels = NULL)
row2 <- ggpubr::ggarrange(p_similarity, p_plant_similarity, ncol = 2, labels = NULL)
ggpubr::ggarrange(row1, row2, nrow = 2, heights = c(1.5, 1))




# ==============================================================================
# MARK: 2.2 Slope Showdown (Aggregated Data Analysis)
# ==============================================================================
# Comparing the slopes of HP vs CP across years using aggregated (plant-level) data.

message("Running Slope Comparison (Aggregated Model)...")
aggregated_data <- pollen_deposition %>%
    group_by(year, plant_id) %>%
    summarise(
        mean_HP = mean(heterospecific_pollen, na.rm = TRUE),
        mean_CP = mean(conspecific_pollen, na.rm = TRUE),
        .groups = "drop"
    ) %>%
    filter(is.finite(mean_HP) & is.finite(mean_CP)) %>%
    mutate(Year = as.factor(year))

# Model on Sqrt Scale (as validated in S4)
fit_sqrt <- lm(sqrt(mean_HP) ~ sqrt(mean_CP) * Year, data = aggregated_data)

# ANOVA results
# print(anova(fit_sqrt))

# Pairwise Compariasons of Slopes
slopes_em <- emtrends(fit_sqrt, pairwise ~ Year, var = "mean_CP")
print(slopes_em$emtrends) # Slope estimates
print(slopes_em$contrasts) # Comparisons

# Visualisation as it will appear in the MS (backtransformed lines + predictions)
message("Generating Backtransformed Plot for Aggregated Data...")

# Create grid for predictions
pred_grid <- expand.grid(
    mean_CP = seq(min(aggregated_data$mean_CP, na.rm = TRUE),
        max(aggregated_data$mean_CP, na.rm = TRUE),
        length.out = 100
    ),
    Year = levels(aggregated_data$Year)
)

# Predict on the sqrt scale and backtransform
preds <- predict(fit_sqrt, newdata = pred_grid, se.fit = TRUE)
pred_grid$pred_sqrt_HP <- preds$fit
pred_grid$se_sqrt_HP <- preds$se.fit

pred_grid$pred_HP <- pred_grid$pred_sqrt_HP^2 # Backtransformation
# approximate 95% CI: +/- 1.96 * SE, clamped at 0 for lower bound before squaring
pred_grid$lwr_HP <- pmax(0, pred_grid$pred_sqrt_HP - 1.96 * pred_grid$se_sqrt_HP)^2
pred_grid$upr_HP <- (pred_grid$pred_sqrt_HP + 1.96 * pred_grid$se_sqrt_HP)^2

# Create plot
p_model <- ggplot() +
    geom_ribbon(data = pred_grid, aes(x = mean_CP, ymin = lwr_HP, ymax = upr_HP, fill = Year), alpha = 0.2) +
    geom_point(data = aggregated_data, aes(x = mean_CP, y = mean_HP, color = Year), alpha = 0.6, size = 2) +
    geom_line(data = pred_grid, aes(x = mean_CP, y = pred_HP, color = Year), linewidth = 1.2) +
    geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "gray50", linewidth = 0.8) +
    scale_color_viridis_d(begin = 0.2, end = 0.8, option = "magma", name = "Year") +
    scale_fill_viridis_d(begin = 0.2, end = 0.8, option = "magma", name = "Year") +
    labs(
        x = "Conspecific Pollen (mean per plant)",
        y = "Heterospecific Pollen (mean per plant)"
    ) +
    theme_classic() +
    theme(
        legend.position = "right"
    )

# Table for Manuscript (ANOVA Results)
message("Generating Model Results Table (ANOVA)...")
aov_res <- as.data.frame(anova(fit_sqrt))
aov_table <- data.frame(
    Predictor = gsub("sqrt\\(mean_CP\\)", "Conspecific Pollen (CP)", rownames(aov_res)),
    Df = aov_res$Df,
    Sum_Sq = round(aov_res$`Sum Sq`, 3),
    Mean_Sq = round(aov_res$`Mean Sq`, 3),
    F_value = round(aov_res$`F value`, 2),
    P_value = format.pval(aov_res$`Pr(>F)`, eps = 0.001, digits = 3),
    stringsAsFactors = FALSE
)
aov_table[aov_table == "NA" | is.na(aov_table)] <- ""


# Table for Manuscript (Pairwise Slope Contrasts)
message("Generating Pairwise Contrasts Table...")
contrasts_res <- as.data.frame(slopes_em$contrasts)
contrasts_table <- data.frame(
    Contrast = contrasts_res$contrast,
    Estimate = round(contrasts_res$estimate, 3),
    SE = round(contrasts_res$SE, 3),
    Df = round(contrasts_res$df, 1),
    t_ratio = round(contrasts_res$t.ratio, 2),
    P_value = format.pval(contrasts_res$p.value, eps = 0.001, digits = 3),
    stringsAsFactors = FALSE
)
contrasts_table[contrasts_table == "NA" | is.na(contrasts_table)] <- ""


# ==============================================================================
# MARK: 2.3 Daily Stability Test (2024 Data)
# ==============================================================================
# Testing if the CP-HP relationship changes day-to-day within 2024.

message("Running Daily Stability Test (2024)...")
agg_data_2024 <- pollen_deposition %>%
    filter(year == 2024) %>%
    group_by(plant_id, day) %>%
    summarise(
        mean_HP = mean(heterospecific_pollen, na.rm = TRUE),
        mean_CP = mean(conspecific_pollen, na.rm = TRUE),
        .groups = "drop"
    )

# Model
fit_daily <- lm(mean_HP ~ mean_CP * as.factor(day), data = agg_data_2024)
# print(anova(fit_daily))
# Result Interpretation:
# The interaction term (mean_CP:as.factor(day)) is not significant (p = 0.366),
# and the main effect of day is also non-significant (p = 0.197).
# This  confirms that the relationship between CP and HP deposition does not
# vary significantly day-to-day. The micro-scale stabilization holds reliable
# throughout 6 days of 2024 despite any behavioral shifts
# or minor weather fluctuations.


# ==============================================================================
# MARK: 2.4 Variance Partitioning (VCA)
# ==============================================================================
# We quantify how much variation in pollen deposition occurs at different
# hierarchical levels: Inter-annual (Year), Intra-annual (Date), Plant (Inflorescence),
# and the base micro-scale (Individual Stigma).

message("Running Variance Partitioning...")

# Step 1: Data Preparation
# We explicitly define the grouping factors used for the random effects in the LMMs.
# We use the square root of HP to stabilize the variance, as confirmed in S4.
# We use the square root of CP to stabilize the variance, as confirmed in S4.
vca_data <- pollen_deposition %>%
    filter(!is.na(heterospecific_pollen) & !is.na(conspecific_pollen)) %>%
    mutate(
        sqrt_HP = sqrt(heterospecific_pollen),
        sqrt_CP = sqrt(conspecific_pollen),
        year_fac = as.factor(year), # Defines the Year level
        date_fac = as.factor(paste(year, day, sep = "_")), # Defines the specific Day level
        plant_id = inflorescence_id # Defines the Plant/Individual level
    )

# Step 2: Two-Part LMM Function definition
# Because we only have fine-scale day-to-day data for 2024, a single fully-nested
# model (Year/Date/Plant) across all three years is rank-deficient. Thus, we run
# two separate models to isolate the specific variance components.
#
# Arguments:
#   data: The pre-processed dataframe (e.g., vca_data) containing the nested factors.
#   variable_col: A string specifying the column name of the response variable to analyze
#                 (e.g., "sqrt_HP" or "sqrt_CP").
#   metric_label: A string used to label the output dataframe rows for visualization
#                 (e.g., "Heterospecific Pollen (Sq)").
# returns: A dataframe with columns: Part, level, vcov, sdcor, percent.
run_twopart_vca <- function(data, variable_col, metric_label) {
    # Helper: Extracts raw variance from LMM random effects, calculates the
    # percentage of total variance explained, and labels the spatial/temporal level.
    #
    # Arguments:
    #   model: The fitted lmer model object.
    #   name: A string label for the "Part" column (e.g., "Inter-Annual").
    #
    # Returns:
    #   A dataframe with columns: Part, level, vcov, sdcor, percent.
    extract_lmer_var <- function(model, name) {
        vc <- VarCorr(model) # Extracts variance components from the fitted LMM.
        df <- as.data.frame(vc) # Converts the variance components to a dataframe.
        if (!("Residual" %in% df$grp)) { # Adds the residual variance component if it is not already present.
            sigma_sq <- attr(vc, "sc")^2 # Calculates the residual variance.
            df <- rbind(df, data.frame(grp = "Residual", var1 = NA, var2 = NA, vcov = sigma_sq, sdcor = attr(vc, "sc"))) # Adds the residual variance component to the dataframe.
        }
        total_var <- sum(df$vcov) # Calculates the total variance.
        df$percent <- (df$vcov / total_var) * 100 # Calculates the percentage of total variance explained by each component.
        df$Part <- name # Adds a "Part" column with the provided name.
        df$level <- dplyr::case_when( # Adds a "level" column with the spatial/temporal level.
            grepl("inflorescence", df$grp) ~ "Plant", # If the group name contains "inflorescence", the level is "Plant".
            grepl("plant_id", df$grp) ~ "Plant", # If the group name contains "plant_id", the level is "Plant".
            df$grp == "year_fac" ~ "Year", # If the group name is "year_fac", the level is "Year".
            df$grp == "date_fac" ~ "Date", # If the group name is "date_fac", the level is "Date".
            df$grp == "Residual" ~ "Stigma", # If the group name is "Residual", the level is "Stigma".
            TRUE ~ "Other" # Otherwise, the level is "Other".
        )
        return(df[, c("Part", "level", "vcov", "sdcor", "percent")])
    }

    # Model A (Inter-Annual): Uses all data (2022-2024) to estimate how much
    # variance belongs to the sweeping 'Year' shifts vs individual 'Plants'.
    f_inter <- as.formula(paste(variable_col, "~ 1 + (1 | year_fac / plant_id)"))
    m_inter <- lmer(f_inter, data = data)
    res_inter <- extract_lmer_var(m_inter, "Inter-Annual")

    # Intra (2024)
    data_24 <- filter(data, year == 2024)
    f_intra <- as.formula(paste(variable_col, "~ 1 + (1 | date_fac / plant_id)"))
    m_intra <- lmer(f_intra, data = data_24)
    res_intra <- extract_lmer_var(m_intra, "Intra-Annual")

    combined <- rbind(res_inter, res_intra)
    combined$Metric <- metric_label
    return(combined)
}

# Run for HP (Sqrt)
res_vca_hp <- run_twopart_vca(vca_data, "sqrt_HP", "Heterospecific Pollen (Sq)")
# print(res_vca_hp) # Suppressed for clean MS output

# Run for CP
res_vca_cp <- run_twopart_vca(vca_data, "sqrt_CP", "Conspecific Pollen (Sq)")
# print(res_vca_cp) # Suppressed for clean MS output


# Define factor levels
all_results <- rbind(res_vca_hp, res_vca_cp)
all_results$level <- factor(all_results$level, levels = c("Year", "Date", "Plant", "Stigma"))

# Ensure the Metric names match the desired target strings before forcing them to factors
all_results$Metric <- dplyr::case_when(
    grepl("Heterospecific", all_results$Metric) ~ "HP",
    grepl("Conspecific", all_results$Metric) ~ "CP",
    TRUE ~ all_results$Metric
)
all_results$Metric <- factor(all_results$Metric, levels = c("HP", "CP"))

# 4. Visualization (Percent only)
p_var <- ggplot(all_results, aes(x = Metric, y = percent, fill = level)) +
    geom_bar(stat = "identity", width = 0.6) +
    facet_wrap(~Part) +
    scale_fill_viridis_d(option = "magma", begin = 0.3, end = 0.9) +
    geom_text(aes(label = ifelse(percent > 1.5, paste0(round(percent, 0), "%"), "")),
        position = position_stack(vjust = 0.5),
        size = 4,
        fontface = "bold",
        color = "black"
    ) +
    labs(
        title = "",
        y = "% of Total Variance",
        x = "",
        fill = "Variance Source"
    ) +
    theme_classic() +
    theme(
        axis.text.x = element_text(face = "bold", angle = 45, hjust = 1, size = 11),
        strip.text = element_text(size = 12, face = "bold"),
        legend.position = "bottom"
    )

library(patchwork)
library(cowplot)

# Add TPD HP icon to the y-axis and TPD CP icon to the x-axis
p_model_icon <- ggdraw(p_model) +
    draw_image("images/Stigma.png", x = 0.11, y = 0.27, hjust = 0.5, vjust = 0.5, width = 0.15, height = 0.15) +
    draw_image("images/TPD_HP.png", x = 0.13, y = 0.88, hjust = 0.5, vjust = 0.5, width = 0.18, height = 0.18) +
    draw_image("images/TPD.png", x = 0.82, y = 0.27, hjust = 0.5, vjust = 0.5, width = 0.18, height = 0.18)

p_combined_fig <- p_model_icon / p_var +
    plot_annotation(tag_levels = "A") +
    plot_layout(heights = c(1, 1))

 print(p_combined_fig)

### Otestovat!!


# ==============================================================================
# MARK: 2.5 Single Visit Deposition (SVD) Analysis
# ==============================================================================
# Comparing efficiency (CP) and messiness (HP) across morphogroups.

message("Running SVD Analysis...")
# 1. Prepare Data
SVD_clean <- SVD_Succisa_22_24 %>%
    rename(species = pollinator_species) %>%
    mutate(
        morphogroup = case_when(
            grepl("Eristalis", species) ~ "Eristalis spp.",
            grepl("Bombus", species) ~ "Bombus spp.",
            species == "Apis mellifera" ~ "Apis mellifera",
            grepl("Syrphus", species) ~ "Syrphus spp.",
            grepl("Helophilus", species) ~ "Helophilus spp.",
            TRUE ~ "Other"
        )
    )

group_counts_svd <- SVD_clean %>%
    count(morphogroup) %>%
    filter(n >= 5)
SVD_final <- SVD_clean %>% filter(morphogroup %in% group_counts_svd$morphogroup)

# 2. Kruskal-Wallis and Dunn's Test for CP
kw_cp <- kruskal.test(conspecific_pollen ~ morphogroup, data = SVD_final)

# 3. Kruskal-Wallis and Dunn's Test for HP
kw_hp <- kruskal.test(heterospecific_pollen ~ morphogroup, data = SVD_final)

library(knitr)
kw_res_df <- data.frame(
    Test = c("Conspecific Pollen (CP)", "Heterospecific Pollen (HP)"),
    `Chi-Squared` = round(c(kw_cp$statistic, kw_hp$statistic), 2),
    df = c(kw_cp$parameter, kw_hp$parameter),
    `p-value` = c(
        format.pval(kw_cp$p.value, eps = 0.001, digits = 3),
        format.pval(kw_hp$p.value, eps = 0.001, digits = 3)
    ),
    check.names = FALSE
)



# 1. Data Cleaning & Grouping for Body Load
Body_clean <- pollen_load_guts_24 %>%
    rename(species = pollinator_species) %>%
    mutate(
        # Create Morphogroups identical to SVD
        morphogroup = case_when(
            grepl("Eristalis", species) ~ "Eristalis spp.",
            grepl("Bombus", species) ~ "Bombus spp.",
            species == "Apis mellifera" ~ "Apis mellifera",
            grepl("Syrphus", species) ~ "Syrphus spp.",
            grepl("Helophilus", species) ~ "Helophilus spp.",
            TRUE ~ "Other"
        )
    )

# Filter for groups with sufficient sample size (N >= 5) for visualization
group_counts_body <- Body_clean %>%
    count(morphogroup) %>%
    filter(n >= 5)
Body_final <- Body_clean %>%
    filter(morphogroup %in% group_counts_body$morphogroup)

# Define pairwise comparisons
body_comparisons <- combn(unique(as.character(Body_final$morphogroup)), 2, simplify = FALSE)

# Filter to keep only significant comparisons
body_comp_A <- body_comparisons[sapply(body_comparisons, function(comp) {
    if (sum(Body_final$morphogroup == comp[1]) < 3 | sum(Body_final$morphogroup == comp[2]) < 3) {
        return(FALSE)
    }
    suppressWarnings(
        wilcox.test(
            Body_final$suc_pra_load[Body_final$morphogroup == comp[1]],
            Body_final$suc_pra_load[Body_final$morphogroup == comp[2]]
        )$p.value < 0.05
    )
})]

body_comp_B <- body_comparisons[sapply(body_comparisons, function(comp) {
    if (sum(Body_final$morphogroup == comp[1]) < 3 | sum(Body_final$morphogroup == comp[2]) < 3) {
        return(FALSE)
    }
    suppressWarnings(
        wilcox.test(
            Body_final$other_pollen_load[Body_final$morphogroup == comp[1]],
            Body_final$other_pollen_load[Body_final$morphogroup == comp[2]]
        )$p.value < 0.05
    )
})]

# Calculate overall p-values for clear subtitling
kw_A <- kruskal.test(suc_pra_load ~ morphogroup, data = Body_final)$p.value
kw_B <- kruskal.test(other_pollen_load ~ morphogroup, data = Body_final)$p.value
text_A <- ifelse(kw_A < 0.001, "p < 0.001", sprintf("p = %.3f", kw_A))
text_B <- ifelse(kw_B < 0.001, "p < 0.001", sprintf("p = %.3f", kw_B))

# Panel A: Conspecific Pollen Load on Body
p_eff_body <- ggplot(Body_final, aes(x = morphogroup, y = suc_pra_load, fill = morphogroup)) +
    geom_boxplot(alpha = 0.6, outlier.shape = NA) +
    scale_fill_viridis_d(option = "mako", begin = 0.3, end = 0.8) +
    geom_jitter(width = 0.2, alpha = 0.5, size = 1.5) +
    ggpubr::stat_compare_means(
        comparisons = body_comp_A,
        label = "p.signif",
        hide.ns = TRUE
    ) +
    labs(
        title = "A. Conspecific Pollen (CP)",
        subtitle = paste("Kruskal-Wallis:", text_A),
        y = "Conspecific Pollen on Body",
        x = "Pollinator Group"
    ) +
    theme_classic() +
    theme(
        axis.text.x = element_text(angle = 45, hjust = 1, face = "italic"),
        legend.position = "none"
    )

# Panel B: Heterospecific Pollen Load on Body
p_mess_body <- ggplot(Body_final, aes(x = morphogroup, y = other_pollen_load, fill = morphogroup)) +
    geom_boxplot(alpha = 0.6, outlier.shape = NA) +
    scale_fill_viridis_d(option = "mako", begin = 0.3, end = 0.8) +
    geom_jitter(width = 0.2, alpha = 0.5, size = 1.5) +
    ggpubr::stat_compare_means(
        comparisons = body_comp_B,
        label = "p.signif",
        hide.ns = TRUE
    ) +
    labs(
        title = "B. Heterospecific Pollen (HP)",
        subtitle = paste("Kruskal-Wallis:", text_B),
        y = "Heterospecific Pollen on Body",
        x = "Pollinator Group"
    ) +
    theme_classic() +
    theme(
        axis.text.x = element_text(angle = 45, hjust = 1, face = "italic"),
        legend.position = "none"
    )

# 2. Data Cleaning & Grouping for SVD
SVD_clean <- SVD_Succisa_22_24 %>%
    rename(
        duration_sec = delka_navstevy,
        year = rok,
        species = pollinator_species
    ) %>%
    mutate(
        # Create Morphogroups
        morphogroup = case_when(
            grepl("Eristalis", species) ~ "Eristalis spp.",
            grepl("Bombus", species) ~ "Bombus spp.",
            species == "Apis mellifera" ~ "Apis mellifera",
            grepl("Syrphus", species) ~ "Syrphus spp.",
            grepl("Helophilus", species) ~ "Helophilus spp.",
            TRUE ~ "Other"
        )
    )

# Filter for groups with sufficient sample size (N > 5) for visualization
group_counts <- SVD_clean %>%
    count(morphogroup) %>%
    filter(n >= 5)
SVD_final <- SVD_clean %>%
    filter(morphogroup %in% group_counts$morphogroup)

svd_comparisons <- combn(unique(as.character(SVD_final$morphogroup)), 2, simplify = FALSE)

# 3. Visualization for SVD

# Calculate overall p-values for clear subtitling
kw_C <- kruskal.test(conspecific_pollen ~ morphogroup, data = SVD_final)$p.value
kw_D <- kruskal.test(heterospecific_pollen ~ morphogroup, data = SVD_final)$p.value
text_C <- ifelse(kw_C < 0.001, "p < 0.001", sprintf("p = %.3f", kw_C))
text_D <- ifelse(kw_D < 0.001, "p < 0.001", sprintf("p = %.3f", kw_D))

# Panel C: Efficiency (CP SVD)
p_eff <- ggplot(SVD_final, aes(x = morphogroup, y = conspecific_pollen, fill = morphogroup)) +
    geom_boxplot(alpha = 0.6, outlier.shape = NA) +
    scale_fill_viridis_d(option = "mako", begin = 0.3, end = 0.8) +
    geom_jitter(width = 0.2, alpha = 0.5, size = 1.5) +
    labs(
        title = "C. Conspecific Pollen (CP)",
        subtitle = paste("Kruskal-Wallis:", text_C),
        y = "Conspecific Pollen SVD",
        x = "Pollinator Group"
    ) +
    theme_classic() +
    theme(
        axis.text.x = element_text(angle = 45, hjust = 1, face = "italic"),
        legend.position = "none"
    )

# Panel D: Messiness (HP SVD)
p_mess <- ggplot(SVD_final, aes(x = morphogroup, y = heterospecific_pollen, fill = morphogroup)) +
    geom_boxplot(alpha = 0.6, outlier.shape = NA) +
    scale_fill_viridis_d(option = "mako", begin = 0.3, end = 0.8) +
    geom_jitter(width = 0.2, alpha = 0.5, size = 1.5) +
    labs(
        title = "D. Heterospecific Pollen (HP)",
        subtitle = paste("Kruskal-Wallis:", text_D),
        y = "Heterospecific Pollen SVD",
        x = "Pollinator Group"
    ) +
    theme_classic() +
    theme(
        axis.text.x = element_text(angle = 45, hjust = 1, face = "italic"),
        legend.position = "none"
    )

# Combine both using patchwork
if (!requireNamespace("patchwork", quietly = TRUE)) install.packages("patchwork")
if (!requireNamespace("cowplot", quietly = TRUE)) install.packages("cowplot")
library(patchwork)
library(cowplot)

p_eff_body_icon <- ggdraw(p_eff_body) + draw_image("images/Pollen_load_CP.png", x = 0.98, y = 0.98, hjust = 1, vjust = 1, width = 0.15, height = 0.15)
p_mess_body_icon <- ggdraw(p_mess_body) + draw_image("images/Pollen_load_HP.png", x = 0.98, y = 0.98, hjust = 1, vjust = 1, width = 0.15, height = 0.15)
p_eff_icon <- ggdraw(p_eff) + draw_image("images/SVD.png", x = 0.98, y = 0.98, hjust = 1, vjust = 1, width = 0.25, height = 0.25)
p_mess_icon <- ggdraw(p_mess) + draw_image("images/SVD_HP.png", x = 0.98, y = 0.98, hjust = 1, vjust = 1, width = 0.25, height = 0.25)

p_combined_all <- (p_eff_body_icon + p_mess_body_icon) / (p_eff_icon + p_mess_icon)
# print(p_combined_all)


# ==============================================================================
# MARK: 2.6 Pollen CP/HP relationship & CV Analysis
# ==============================================================================
# Calculating Coefficients of Variation for robustness check.

message("Calculating CVs...")
cv_stigma <- pollen_deposition %>%
    summarise(
        CP = sd(conspecific_pollen, na.rm = TRUE) / mean(conspecific_pollen, na.rm = TRUE) * 100,
        HP = sd(heterospecific_pollen, na.rm = TRUE) / mean(heterospecific_pollen, na.rm = TRUE) * 100
    ) %>%
    mutate(Compartment = "Stigma")

# Body/Gut requires 'pollen_load_guts_24'
cv_body <- pollen_load_guts_24 %>%
    summarise(
        CP = sd(suc_pra_load, na.rm = TRUE) / mean(suc_pra_load, na.rm = TRUE) * 100,
        HP = sd(other_pollen_load, na.rm = TRUE) / mean(other_pollen_load, na.rm = TRUE) * 100
    ) %>%
    mutate(Compartment = "Body")

cv_table <- bind_rows(cv_stigma, cv_body)
# print(cv_table)

# CV by year

cv_by_year <- pollen_deposition %>%
    group_by(year) %>%
    summarise(
        CP = sd(conspecific_pollen, na.rm = TRUE) / mean(conspecific_pollen, na.rm = TRUE) * 100,
        HP = sd(heterospecific_pollen, na.rm = TRUE) / mean(heterospecific_pollen, na.rm = TRUE) * 100
    )
# print(cv_by_year)


# ==============================================================================
# MARK: 2.7 Detailed Coefficient of Variation (CV) and Means Breakdown
# ==============================================================================
# Further analysis of CV and Mean/SE for Body, SVD and TPD compartments + TPD in years.

# 1. Stigma
cv_stigma <- pollen_deposition %>%
    summarise(
        CP = sd(conspecific_pollen, na.rm = TRUE) / mean(conspecific_pollen, na.rm = TRUE) * 100,
        HP = sd(heterospecific_pollen, na.rm = TRUE) / mean(heterospecific_pollen, na.rm = TRUE) * 100
    ) %>%
    mutate(Compartment = "Stigma")

mean_se_stigma <- pollen_deposition %>%
    summarise(
        CP_mean = mean(conspecific_pollen, na.rm = TRUE),
        CP_se = sd(conspecific_pollen, na.rm = TRUE) / sqrt(sum(!is.na(conspecific_pollen))),
        HP_mean = mean(heterospecific_pollen, na.rm = TRUE),
        HP_se = sd(heterospecific_pollen, na.rm = TRUE) / sqrt(sum(!is.na(heterospecific_pollen)))
    ) %>%
    mutate(Compartment = "Stigma")

# 2. Body
if (!exists("pollen_load_guts_24")) {
    data("pollen_load_guts_24", package = "HanPolNet")
}

cv_body <- pollen_load_guts_24 %>%
    summarise(
        CP = sd(suc_pra_load, na.rm = TRUE) / mean(suc_pra_load, na.rm = TRUE) * 100,
        HP = sd(other_pollen_load, na.rm = TRUE) / mean(other_pollen_load, na.rm = TRUE) * 100
    ) %>%
    mutate(Compartment = "Body")

mean_se_body <- pollen_load_guts_24 %>%
    summarise(
        CP_mean = mean(suc_pra_load, na.rm = TRUE),
        CP_se = sd(suc_pra_load, na.rm = TRUE) / sqrt(sum(!is.na(suc_pra_load))),
        HP_mean = mean(other_pollen_load, na.rm = TRUE),
        HP_se = sd(other_pollen_load, na.rm = TRUE) / sqrt(sum(!is.na(other_pollen_load)))
    ) %>%
    mutate(Compartment = "Body")

# 3. SVD
cv_SVD <- SVD_Succisa_22_24 %>%
    summarise(
        CP = sd(conspecific_pollen, na.rm = TRUE) / mean(conspecific_pollen, na.rm = TRUE) * 100,
        HP = sd(heterospecific_pollen, na.rm = TRUE) / mean(heterospecific_pollen, na.rm = TRUE) * 100
    ) %>%
    mutate(Compartment = "SVD")

mean_se_SVD <- SVD_Succisa_22_24 %>%
    summarise(
        CP_mean = mean(conspecific_pollen, na.rm = TRUE),
        CP_se = sd(conspecific_pollen, na.rm = TRUE) / sqrt(sum(!is.na(conspecific_pollen))),
        HP_mean = mean(heterospecific_pollen, na.rm = TRUE),
        HP_se = sd(heterospecific_pollen, na.rm = TRUE) / sqrt(sum(!is.na(heterospecific_pollen)))
    ) %>%
    mutate(Compartment = "SVD")

# Combine and Reshape CV
cv_data <- bind_rows(cv_stigma, cv_body, cv_SVD) %>%
    pivot_longer(cols = c(CP, HP), names_to = "Pollen_Type", values_to = "CV")

# Combine and Reshape Mean/SE
mean_se_data_cp <- bind_rows(mean_se_stigma, mean_se_body, mean_se_SVD) %>%
    select(Compartment, mean = CP_mean, se = CP_se) %>%
    mutate(Pollen_Type = "CP")

mean_se_data_hp <- bind_rows(mean_se_stigma, mean_se_body, mean_se_SVD) %>%
    select(Compartment, mean = HP_mean, se = HP_se) %>%
    mutate(Pollen_Type = "HP")

mean_se_data <- bind_rows(mean_se_data_cp, mean_se_data_hp)

# CV by year (Stigma)
cv_by_year <- pollen_deposition %>%
    filter(!is.na(year)) %>%
    group_by(year) %>%
    summarise(
        CP = sd(conspecific_pollen, na.rm = TRUE) / mean(conspecific_pollen, na.rm = TRUE) * 100,
        HP = sd(heterospecific_pollen, na.rm = TRUE) / mean(heterospecific_pollen, na.rm = TRUE) * 100,
        .groups = "drop"
    ) %>%
    pivot_longer(cols = c(CP, HP), names_to = "Pollen_Type", values_to = "CV") %>%
    mutate(Year = factor(as.character(year)))

# Mean/SE by year (Stigma)
mean_se_by_year_raw <- pollen_deposition %>%
    filter(!is.na(year)) %>%
    group_by(year) %>%
    summarise(
        CP_mean = mean(conspecific_pollen, na.rm = TRUE),
        CP_se = sd(conspecific_pollen, na.rm = TRUE) / sqrt(sum(!is.na(conspecific_pollen))),
        HP_mean = mean(heterospecific_pollen, na.rm = TRUE),
        HP_se = sd(heterospecific_pollen, na.rm = TRUE) / sqrt(sum(!is.na(heterospecific_pollen))),
        .groups = "drop"
    ) %>%
    mutate(Year = factor(as.character(year)))

mean_se_year_cp <- mean_se_by_year_raw %>%
    select(Year, mean = CP_mean, se = CP_se) %>%
    mutate(Pollen_Type = "CP")

mean_se_year_hp <- mean_se_by_year_raw %>%
    select(Year, mean = HP_mean, se = HP_se) %>%
    mutate(Pollen_Type = "HP")

mean_se_by_year <- bind_rows(mean_se_year_cp, mean_se_year_hp)

# Determine shared Y-axis limit for CV
max_cv <- max(c(cv_data$CV, cv_by_year$CV), na.rm = TRUE)
y_limit_max <- max_cv * 1.7

cv_data$Compartment <- as.character(cv_data$Compartment)
cv_data$Compartment[cv_data$Compartment == "Stigma"] <- "TPD"
mean_se_data$Compartment <- as.character(mean_se_data$Compartment)
mean_se_data$Compartment[mean_se_data$Compartment == "Stigma"] <- "TPD"

comp_levels <- c("Body", "SVD", "TPD")
cv_data$Compartment <- factor(cv_data$Compartment, levels = comp_levels)
mean_se_data$Compartment <- factor(mean_se_data$Compartment, levels = comp_levels)

library(patchwork)
library(ggtext)

add_icons <- function(df) {
    df$icon_path <- NA
    df$icon_path[df$Compartment == "Body" & df$Pollen_Type == "CP"] <- "images/Pollen_load_CP.png"
    df$icon_path[df$Compartment == "Body" & df$Pollen_Type == "HP"] <- "images/Pollen_load_HP.png"
    df$icon_path[df$Compartment == "SVD" & df$Pollen_Type == "CP"] <- "images/SVD.png"
    df$icon_path[df$Compartment == "SVD" & df$Pollen_Type == "HP"] <- "images/SVD_HP.png"
    df$icon_path[df$Compartment == "TPD" & df$Pollen_Type == "CP"] <- "images/TPD.png"
    df$icon_path[df$Compartment == "TPD" & df$Pollen_Type == "HP"] <- "images/TPD_HP.png"
    
    df$icon_height <- NA
    df$icon_height[df$Compartment == "Body"] <- 25
    df$icon_height[df$Compartment == "SVD"] <- 40
    df$icon_height[df$Compartment == "TPD"] <- 40
    
    df$icon_html <- sprintf("<img src='%s' height='%d' />", df$icon_path, df$icon_height)
    return(df)
}

cv_data <- add_icons(cv_data)
mean_se_data <- add_icons(mean_se_data)

cv_by_year$Compartment <- "TPD"
cv_by_year <- add_icons(cv_by_year)
mean_se_by_year$Compartment <- "TPD"
mean_se_by_year <- add_icons(mean_se_by_year)

# Plot A: Compartments CV
cv_data$icon_y <- ifelse(cv_data$Compartment == "Body",
                         ifelse(cv_data$Pollen_Type == "CP", max_cv * 1.20, max_cv * 1.45),
                         max_cv * 1.15)

p_cv <- ggplot(cv_data, aes(x = Compartment, y = CV, fill = Pollen_Type)) +
    geom_bar(stat = "identity", position = position_dodge(width = 0.9), color = "black", width = 0.8) +
    geom_text(aes(label = round(CV, 1)), position = position_dodge(width = 0.9), vjust = -0.5, size = 4) +
    ggtext::geom_richtext(aes(y = icon_y, label = icon_html, group = Pollen_Type), 
                          position = position_dodge(width = 0.9),
                          vjust = 0, fill = NA, label.color = NA, 
                          label.padding = grid::unit(rep(0, 4), "pt")) +
    scale_fill_viridis_d(
        option = "magma", begin = 0.3, end = 0.8,
        labels = c("CP" = "Conspecific", "HP" = "Heterospecific")
    ) +
    scale_y_continuous(limits = c(0, max_cv * 1.70)) +
    coord_cartesian(clip = "off") +
    theme(plot.margin = margin(t = 20, r = 5, b = 5, l = 5, unit = "pt")) +
    labs(
        title = "A) Compartments (CV)",
        y = "CV (%)",
        x = "",
        fill = "Pollen Type"
    ) +
    theme_classic() +
    theme(
        axis.text.x = element_text(size = 12, face = "bold"),
        axis.text.y = element_text(size = 12),
        legend.position = "none"
    )

# Plot B: Stigma per year CV
max_cv_year <- max(cv_by_year$CV, na.rm = TRUE)

cv_by_year$icon_y <- max_cv_year * 1.15

p_cv_year <- ggplot(cv_by_year, aes(x = Year, y = CV, fill = Pollen_Type)) +
    geom_bar(stat = "identity", position = position_dodge(width = 0.9), color = "black", width = 0.8) +
    geom_text(aes(label = round(CV, 1)), position = position_dodge(width = 0.9), vjust = -0.5, size = 4) +
    ggtext::geom_richtext(aes(x = Year, y = icon_y, label = icon_html, group = Pollen_Type), 
                          position = position_dodge(width = 0.9),
                          fill = NA, label.color = NA, vjust = 0) +
    scale_fill_viridis_d(
        option = "magma", begin = 0.3, end = 0.8,
        labels = c("CP" = "Conspecific", "HP" = "Heterospecific")
    ) +
    scale_y_continuous(limits = c(0, max_cv_year * 1.70)) +
    coord_cartesian(clip = "off") +
    theme(plot.margin = margin(t = 20, r = 5, b = 5, l = 5, unit = "pt")) +
    labs(
        title = "B) TPD per Year (CV)",
        y = "",
        x = "",
        fill = "Pollen Type"
    ) +
    theme_classic() +
    theme(
        axis.text.x = element_text(size = 12, face = "bold"),
        axis.text.y = element_text(size = 12),
        legend.position = "none"
    )

max_mean_se <- max(mean_se_data$mean + mean_se_data$se, na.rm = TRUE)

mean_se_data$icon_y <- ifelse(mean_se_data$Compartment == "Body",
                              ifelse(mean_se_data$Pollen_Type == "CP", max_mean_se * 1.20, max_mean_se * 1.45),
                              max_mean_se * 1.15)

# Plot C: Compartments Mean + SE
p_mean_comp <- ggplot(mean_se_data, aes(x = Compartment, y = mean, fill = Pollen_Type)) +
    geom_bar(stat = "identity", position = position_dodge(width = 0.9), color = "black", width = 0.8) +
    geom_errorbar(aes(ymin = pmax(0, mean - se), ymax = mean + se), position = position_dodge(width = 0.9), width = 0.25) +
    ggtext::geom_richtext(aes(y = icon_y, label = icon_html, group = Pollen_Type), 
                          position = position_dodge(width = 0.9),
                          vjust = 0, fill = NA, label.color = NA, 
                          label.padding = grid::unit(rep(0, 4), "pt")) +
    scale_fill_viridis_d(
        option = "magma", begin = 0.3, end = 0.8,
        labels = c("CP" = "Conspecific", "HP" = "Heterospecific")
    ) +
    scale_y_continuous(limits = c(0, max_mean_se * 1.60)) +
    coord_cartesian(clip = "off") +
    theme(plot.margin = margin(t = 20, r = 5, b = 5, l = 5, unit = "pt")) +
    labs(
        title = "C) Compartments (Mean)",
        y = "Mean Pollen Count",
        x = "Compartment",
        fill = "Pollen Type"
    ) +
    theme_classic() +
    theme(
        axis.text.x = element_text(size = 12, face = "bold"),
        axis.text.y = element_text(size = 12),
        legend.position = "none"
    )

# Plot D: Stigma per year Mean + SE
max_mean_year <- max(mean_se_by_year$mean + mean_se_by_year$se, na.rm = TRUE)

mean_se_by_year$icon_y <- max_mean_year * 1.15

p_mean_year <- ggplot(mean_se_by_year, aes(x = Year, y = mean, fill = Pollen_Type)) +
    geom_bar(stat = "identity", position = position_dodge(width = 0.9), color = "black", width = 0.8) +
    geom_errorbar(aes(ymin = pmax(0, mean - se), ymax = mean + se), position = position_dodge(width = 0.9), width = 0.25) +
    ggtext::geom_richtext(aes(x = Year, y = icon_y, label = icon_html, group = Pollen_Type), 
                          position = position_dodge(width = 0.9),
                          fill = NA, label.color = NA, vjust = 0) +
    scale_fill_viridis_d(
        option = "magma", begin = 0.3, end = 0.8,
        labels = c("CP" = "Conspecific", "HP" = "Heterospecific")
    ) +
    scale_y_continuous(limits = c(0, max_mean_year * 1.60)) +
    coord_cartesian(clip = "off") +
    theme(plot.margin = margin(t = 20, r = 5, b = 5, l = 5, unit = "pt")) +
    labs(
        title = "D) TPD per Year (Mean)",
        y = "",
        x = "Year",
        fill = "Pollen Type"
    ) +
    theme_classic() +
    theme(
        axis.text.x = element_text(size = 12, face = "bold"),
        axis.text.y = element_text(size = 12),
        legend.position = "none"
    )

# Combine
final_cv_plot <- (p_cv + p_cv_year) / (p_mean_comp + p_mean_year) +
    plot_layout(guides = "collect") &
    theme(legend.position = "bottom") &
    plot_annotation(title = "Variability and Means of Pollen Counts")
 print(final_cv_plot)






message("Running Model Selection via ranova()...")

# ==============================================================================
# 1. Inter-Annual Model Testing (Years 2022-2024)
# Tests variance for: (1) Year overall, and (2) Plant nested within Year
# ==============================================================================

# Fit the full model for Heterospecific Pollen (HP)
# Note: lmerTest overrides lme4's lmer() to include p-value calculations
m_inter_hp <- lmer(sqrt_HP ~ 1 + (1 | year_fac / plant_id), data = vca_data)

# Run the automated Likelihood Ratio Tests for all random effects
# cat("\n--- Significance Test: Inter-Annual HP Variance ---\n")
test_inter_hp <- ranova(m_inter_hp)
# print(test_inter_hp)


# ==============================================================================
# 2. Intra-Annual Model Testing (2024 Only)
# Tests variance for: (1) Date overall, and (2) Plant nested within Date
# ==============================================================================

# Filter data for 2024
data_24 <- filter(vca_data, year == 2024)

# Fit the full model for the fine-scale temporal data
m_intra_hp <- lmer(sqrt_HP ~ 1 + (1 | date_fac / plant_id), data = data_24)

# Run the automated Likelihood Ratio Tests
# cat("\n--- Significance Test: Intra-Annual HP Variance ---\n")
test_intra_hp <- ranova(m_intra_hp)
# print(test_intra_hp)

# (Repeat the above blocks for sqrt_CP by just changing the response variable)


# ==============================================================================
# MARK: 3. THE VARIANCE FILTER (From Micro-Scale Chaos to Macro-Scale Stability)
# ==============================================================================

# ==============================================================================
# MARK: 3.1 Monte Carlo SVD Bootstrapping (Year-by-Year with Global Pool)
# ==============================================================================
message("Running Monte Carlo Simulation per year (Global SVD Pool)...")
library(patchwork)

set.seed(42)
n_sim <- 10000

# 1. Establish the Global SVD Pool
# We use the entire dataset because pollinator morphology/efficiency is assumed constant
global_emp_svd_cp <- SVD_Succisa_22_24$conspecific_pollen[!is.na(SVD_Succisa_22_24$conspecific_pollen)]
global_emp_svd_hp <- SVD_Succisa_22_24$heterospecific_pollen[!is.na(SVD_Succisa_22_24$heterospecific_pollen)]

# Initialize empty dataframes for plotting and stats
df_sim_cp <- data.frame()
df_sim_hp <- data.frame()
ks_results <- data.frame()

years <- c(2022, 2023, 2024)

for (y in years) {
    # 2. Extract year-specific final stigmas
    stigma_y <- pollen_deposition %>% filter(year == y)
    emp_stigma_cp <- stigma_y$conspecific_pollen[!is.na(stigma_y$conspecific_pollen)]
    emp_stigma_hp <- stigma_y$heterospecific_pollen[!is.na(stigma_y$heterospecific_pollen)]

    # 3. Calculate year-specific visitation rate (N)
    # Target (Yearly Stigma CP Mean) / Efficiency (Global SVD CP Mean)
    N_visits <- round(mean(emp_stigma_cp) / mean(global_emp_svd_cp))

    # 4. Run the simulation using the GLOBAL SVD pool
    sim_cp <- replicate(n_sim, sum(sample(global_emp_svd_cp, size = N_visits, replace = TRUE)))
    sim_hp <- replicate(n_sim, sum(sample(global_emp_svd_hp, size = N_visits, replace = TRUE)))

    # 5. Run K-S statistical tests
    ks_cp <- ks.test(emp_stigma_cp, sim_cp)
    ks_hp <- ks.test(emp_stigma_hp, sim_hp)

    # Run overlapping tests
    ov_cp <- overlapping::overlap(list(emp_stigma_cp, sim_cp))
    ov_hp <- overlapping::overlap(list(emp_stigma_hp, sim_hp))

    # Save statistics
    ks_results <- rbind(ks_results, data.frame(
        Year = y,
        Estimated_Visits = N_visits,
        Obs_Mean_CP = round(mean(emp_stigma_cp), 1), Sim_Mean_CP = round(mean(sim_cp), 1),
        KS_CP_D = round(ks_cp$statistic, 3), KS_CP_p = signif(ks_cp$p.value, 3), OVL_CP = round(ov_cp$OV, 3),
        Obs_Mean_HP = round(mean(emp_stigma_hp), 1), Sim_Mean_HP = round(mean(sim_hp), 1),
        KS_HP_D = round(ks_hp$statistic, 3), KS_HP_p = signif(ks_hp$p.value, 3), OVL_HP = round(ov_hp$OV, 3)
    ))

    # Save data for plotting
    df_sim_cp <- rbind(
        df_sim_cp,
        data.frame(Year = factor(y), Pollen = emp_stigma_cp, Type = "Observed TPD"),
        data.frame(Year = factor(y), Pollen = sim_cp, Type = "Simulated (Averaged SVDs)")
    )
    df_sim_hp <- rbind(
        df_sim_hp,
        data.frame(Year = factor(y), Pollen = emp_stigma_hp, Type = "Observed TPD"),
        data.frame(Year = factor(y), Pollen = sim_hp, Type = "Simulated (Averaged SVDs)")
    )
}



# ==============================================================================
# 3.2 Plotting the Per-Year Simulation (8-Panel Original Layout)
# ==============================================================================
# Global Stigmas
emp_CP_global <- pollen_deposition$conspecific_pollen[!is.na(pollen_deposition$conspecific_pollen)]
emp_HP_global <- pollen_deposition$heterospecific_pollen[!is.na(pollen_deposition$heterospecific_pollen)]
n_vis_global <- max(1, round(mean(emp_CP_global) / mean(global_emp_svd_cp)))

make_mc_plot <- function(emp, svd_pool, n_vis, title_text, col_obs, img_path) {
    sim <- replicate(n_sim, sum(sample(svd_pool, size = n_vis, replace = TRUE)))

    # Compute statistics
    ks_res <- ks.test(emp, sim)
    ov_res <- overlapping::overlap(list(emp, sim))

    annot_text <- sprintf("Overlap: %.1f%%\nKS D = %.3f", ov_res$OV * 100, ks_res$statistic)

    df <- data.frame(
        Value = c(emp, sim),
        Type = factor(
            c(rep("Observed TPD", length(emp)), rep("Simulated (Averaged SVDs)", length(sim))),
            levels = c("Observed TPD", "Simulated (Averaged SVDs)")
        )
    )

    max_x_val <- as.numeric(quantile(df$Value, 0.98))

    p <- ggplot(df, aes(x = Value, fill = Type)) +
        geom_density(alpha = 0.6, color = "white", linewidth = 0.2) +
        coord_cartesian(xlim = c(0, max_x_val)) +
        theme_classic() +
        labs(title = title_text, subtitle = annot_text, x = "Pollen Count", y = "Density") +
        scale_fill_manual(values = c("Observed TPD" = col_obs, "Simulated (Averaged SVDs)" = "gray50")) +
        theme(
            plot.title = ggtext::element_markdown(face = "bold", size = 11, margin = margin(t = 15, b = 15)),
            plot.subtitle = element_text(size = 9, color = "gray20"),
            legend.position = "none"
        )
    
    img <- magick::image_read(img_path)
    p_drawn <- cowplot::ggdraw(p) + cowplot::draw_image(img, x = 0.75, y = 0.45, width = 0.15, height = 0.3)
    
    return(p_drawn)
}

# Colors
col_global <- viridisLite::viridis(1, begin = 0.5, option = "magma")
if (!requireNamespace("viridisLite", quietly = TRUE)) install.packages("viridisLite")
viridis_cols <- viridisLite::viridis(3, begin = 0.2, end = 0.8, option = "magma")

inner_legend <- theme(
    legend.position = c(1, 1),
    legend.justification = c(1, 1),
    legend.title = element_blank(),
    legend.background = element_rect(fill = alpha("white", 0.7), color = NA),
    legend.key = element_rect(fill = "transparent")
)

# Row 1: Global
pA <- make_mc_plot(emp_CP_global, global_emp_svd_cp, n_vis_global, "A. Global Conspecific Pollen", col_global, "images/TPD.png")
pB <- make_mc_plot(emp_HP_global, global_emp_svd_hp, n_vis_global, "B. Global Heterospecific Pollen", col_global, "images/TPD_HP.png")

# Row 2: 2022
emp_CP_22 <- pollen_deposition$conspecific_pollen[pollen_deposition$year == 2022]
emp_CP_22 <- emp_CP_22[!is.na(emp_CP_22)]
emp_HP_22 <- pollen_deposition$heterospecific_pollen[pollen_deposition$year == 2022]
emp_HP_22 <- emp_HP_22[!is.na(emp_HP_22)]
n_vis_22 <- max(1, round(mean(emp_CP_22) / mean(global_emp_svd_cp)))
pC <- make_mc_plot(emp_CP_22, global_emp_svd_cp, n_vis_22, "C. 2022 Conspecific Pollen", viridis_cols[1], "images/TPD.png")
pD <- make_mc_plot(emp_HP_22, global_emp_svd_hp, n_vis_22, "D. 2022 Heterospecific Pollen", viridis_cols[1], "images/TPD_HP.png")

# Row 3: 2023
emp_CP_23 <- pollen_deposition$conspecific_pollen[pollen_deposition$year == 2023]
emp_CP_23 <- emp_CP_23[!is.na(emp_CP_23)]
emp_HP_23 <- pollen_deposition$heterospecific_pollen[pollen_deposition$year == 2023]
emp_HP_23 <- emp_HP_23[!is.na(emp_HP_23)]
n_vis_23 <- max(1, round(mean(emp_CP_23) / mean(global_emp_svd_cp)))
pE <- make_mc_plot(emp_CP_23, global_emp_svd_cp, n_vis_23, "E. 2023 Conspecific Pollen", viridis_cols[2], "images/TPD.png")
pF <- make_mc_plot(emp_HP_23, global_emp_svd_hp, n_vis_23, "F. 2023 Heterospecific Pollen", viridis_cols[2], "images/TPD_HP.png")

# Row 4: 2024
emp_CP_24 <- pollen_deposition$conspecific_pollen[pollen_deposition$year == 2024]
emp_CP_24 <- emp_CP_24[!is.na(emp_CP_24)]
emp_HP_24 <- pollen_deposition$heterospecific_pollen[pollen_deposition$year == 2024]
emp_HP_24 <- emp_HP_24[!is.na(emp_HP_24)]
n_vis_24 <- max(1, round(mean(emp_CP_24) / mean(global_emp_svd_cp)))
pG <- make_mc_plot(emp_CP_24, global_emp_svd_cp, n_vis_24, "G. 2024 Conspecific Pollen", viridis_cols[3], "images/TPD.png")
pH <- make_mc_plot(emp_HP_24, global_emp_svd_hp, n_vis_24, "H. 2024 Heterospecific Pollen", viridis_cols[3], "images/TPD_HP.png")

p_grid <- (pA + pB) / (pC + pD) / (pE + pF) / (pG + pH)

# Create a dummy plot to extract a single global legend to place at the bottom
dummy_df <- data.frame(
    Value = 1,
    Type = factor(
        c("Observed TPD (Global)", "Observed TPD (2022)", "Observed TPD (2023)", "Observed TPD (2024)", "Simulated (Averaged SVDs)"), 
        levels = c("Observed TPD (Global)", "Observed TPD (2022)", "Observed TPD (2023)", "Observed TPD (2024)", "Simulated (Averaged SVDs)")
    )
)
dummy_p <- ggplot(dummy_df, aes(x = Value, fill = Type)) + 
    geom_density() + 
    scale_fill_manual(values = c(
        "Observed TPD (Global)" = col_global, 
        "Observed TPD (2022)" = viridis_cols[1],
        "Observed TPD (2023)" = viridis_cols[2],
        "Observed TPD (2024)" = viridis_cols[3],
        "Simulated (Averaged SVDs)" = "gray50"
    )) +
    theme_classic() + 
    theme(
        legend.position = "bottom", 
        legend.title = element_blank(), 
        legend.text = element_text(size = 11)
    ) + 
    guides(fill = guide_legend(nrow = 1))

leg_plot <- cowplot::ggdraw(cowplot::get_legend(dummy_p))

p_combined_mc <- p_grid / leg_plot + plot_layout(heights = c(1, 1, 1, 1, 0.05))
# print(p_combined_mc)



library(overlapping)

# Compute simulated global CP and HP for the overlap test
simulated_stigma_CP <- replicate(n_sim, sum(sample(global_emp_svd_cp, size = n_vis_global, replace = TRUE)))
simulated_stigma_HP <- replicate(n_sim, sum(sample(global_emp_svd_hp, size = n_vis_global, replace = TRUE)))

# Calculate the overlapping area (returns a value between 0 and 1)
# Comparing global empirical CP vs global simulated CP
overlap_result_cp <- overlap(list(emp_CP_global, simulated_stigma_CP))
#cat("\n--- Overlap between Empirical and Simulated Global CP ---\n")
#print(overlap_result_cp$OV)

# Comparing global empirical HP vs global simulated HP
overlap_result_hp <- overlap(list(emp_HP_global, simulated_stigma_HP))
#cat("\n--- Overlap between Empirical and Simulated Global HP ---\n")
#print(overlap_result_hp$OV)


# Remove everything and clear environment






# ==============================================================================
# MARK: MANUSCRIPT FIGURES AND TABLES (QUARTO CHUNKS)
# ==============================================================================

## ---- fig-spatial-temporal-abundance
print(spatial_temporal_plot)

## ---- fig-community-stability
print(ggpubr::ggarrange(row1, row2, nrow = 2, heights = c(1.5, 1)))

## ---- fig-plots-2
print(final_cv_plot)

## ---- fig-plots-3
print(p_combined_fig)

## ---- fig-body-svd
print(p_combined_all)

## ---- fig-monte-carlo-svd
print(p_combined_mc)

## ---- fig-plant-pollinator-panel
# Read and process images
# image_trim() removes the surrounding whitespace

img_A <- image_read("images/IMG_2335_small.jpg") %>% image_trim() # visitation
img_B <- image_read("images/P8197678.jpg") %>% image_trim() # Anther Detail
img_C <- image_read("images/P8197736.jpg") %>% image_trim() # Stigma
img_D <- image_read("images/Blizna_Suc_pra_2.jpg") %>% image_trim() # Stigma pollen

# Create plot objects
# fitting the image into the draw area, scale down to prevent overlap with labels
p_A <- ggdraw() + draw_image(img_A, scale = 0.9)
p_B <- ggdraw() + draw_image(img_B, scale = 0.8)
p_C <- ggdraw() + draw_image(img_C, scale = 1)
p_D <- ggdraw() + draw_image(img_D, scale = 1)

# Arrange in a grid
# Using labels="AUTO" creates A, B, C, D automatically
# Adjusted label size and placement with margins for labels
plant_pollinator_panel <- plot_grid(p_A, p_B, p_C, p_D,
    labels = "AUTO",
    label_size = 18,
    label_x = 0.02,
    label_y = 0.98,
    label_fontface = "bold",
    ncol = 2,
    align = "hv",
    axis = "tb"
)
print(plant_pollinator_panel)




## ---- export-publication-data
# ==============================================================================
# Export Data for Publication

output_dir <- file.path("output", "publication_data")
if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
}

# Clean and export pollen deposition dataset
pollen_deposition_export <- pollen_deposition %>%
    select(id, year, plant_id, conspecific_pollen, heterospecific_pollen, pollen_total)

write.csv(pollen_deposition_export, file.path(output_dir, "pollen_deposition.csv"), row.names = FALSE)

if (exists("SVD_clean")) {
    SVD_export <- SVD_clean %>%
        select(id, year, morphogroup, species, duration_sec, conspecific_pollen, heterospecific_pollen)
    write.csv(SVD_export, file.path(output_dir, "SVD.csv"), row.names = FALSE)
}

if (exists("final_table")) {
    network_export <- final_table %>%
        select(Year, H2, Succisa_d, Succisa_H, Slope, Mean_HP, Succisa_Abundance, Total_Abundance)
    write.csv(network_export, file.path(output_dir, "network_metrics.csv"), row.names = FALSE)
}

# Copy raw data files that are used for the analyses into the publication_data folder
invisible(file.copy(file.path("data", "interaction_data_all_22_24.csv"), file.path(output_dir, "interaction_data_all_22_24.csv"), overwrite = TRUE))
invisible(file.copy(file.path("data", "interaction_data_Succisa_22_24.csv"), file.path(output_dir, "interaction_data_Succisa_22_24.csv"), overwrite = TRUE))
invisible(file.copy(file.path("data", "plant_abundance_22_24.csv"), file.path(output_dir, "plant_abundance_22_24.csv"), overwrite = TRUE))
invisible(file.copy(file.path("data", "pollen_load_and_guts_2024_Succisa_pratensis.csv"), file.path(output_dir, "pollen_load_and_guts_2024_Succisa_pratensis.csv"), overwrite = TRUE))

# Export Figures
fig_dir <- file.path("output", "figures")
if (!dir.exists(fig_dir)) {
    dir.create(fig_dir, recursive = TRUE)
}

library(ggplot2)
if (!requireNamespace("svglite", quietly = TRUE)) install.packages("svglite", repos = "http://cran.us.r-project.org")

ggsave(file.path(fig_dir, "fig_spatial_temporal_abundance.png"), plot = spatial_temporal_plot, width = 8, height = 9, dpi = 300, bg = "white")
ggsave(file.path(fig_dir, "fig_spatial_temporal_abundance.svg"), plot = spatial_temporal_plot, width = 8, height = 9, bg = "white")

community_stability_plot <- ggpubr::ggarrange(row1, row2, nrow = 2, heights = c(1.5, 1))
ggsave(file.path(fig_dir, "fig_community_stability.png"), plot = community_stability_plot, width = 10, height = 8, dpi = 300, bg = "white")
ggsave(file.path(fig_dir, "fig_community_stability.svg"), plot = community_stability_plot, width = 10, height = 8, bg = "white")

ggsave(file.path(fig_dir, "fig_cv_plot.png"), plot = final_cv_plot, width = 10, height = 8, dpi = 300, bg = "white")
ggsave(file.path(fig_dir, "fig_cv_plot.svg"), plot = final_cv_plot, width = 10, height = 8, bg = "white")

ggsave(file.path(fig_dir, "fig_model_vca.png"), plot = p_combined_fig, width = 10, height = 10, dpi = 300, bg = "white")
ggsave(file.path(fig_dir, "fig_model_vca.svg"), plot = p_combined_fig, width = 10, height = 10, bg = "white")

ggsave(file.path(fig_dir, "fig_body_svd.png"), plot = p_combined_all, width = 12, height = 10, dpi = 300, bg = "white")
ggsave(file.path(fig_dir, "fig_body_svd.svg"), plot = p_combined_all, width = 12, height = 10, bg = "white")

ggsave(file.path(fig_dir, "fig_monte_carlo.png"), plot = p_combined_mc, width = 12, height = 12, dpi = 300, bg = "white")
ggsave(file.path(fig_dir, "fig_monte_carlo.svg"), plot = p_combined_mc, width = 12, height = 12, bg = "white")

ggsave(file.path(fig_dir, "fig_plant_pollinator_panel.png"), plot = plant_pollinator_panel, width = 10, height = 8, dpi = 300, bg = "white")
