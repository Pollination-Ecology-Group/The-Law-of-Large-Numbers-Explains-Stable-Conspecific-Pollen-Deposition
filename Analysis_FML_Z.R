# ==============================================================================
# MASTER ANALYSIS SCRIPT: Linking Pollen Deposition Dynamics to Network Structure
# ==============================================================================
# Project: Succisa pratensis Pollination Ecology
# Author: Jakub Štenc
# Description: This script aggregates all statistical analyses and model diagnostics
#              from the manuscript and supplementary material for review.
# ==============================================================================

# ==============================================================================
# 0. SETUP & LIBRARIES
# ==============================================================================

# Load required packages
if (!require("devtools")) install.packages("devtools")
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
library(dunn.test)
library(gridExtra)

# Check for HanPolNet package installation
if (!require("HanPolNet")) {
    devtools::install("local_packages/HanPolNet", upgrade = "never")
    library(HanPolNet)
}

# Set global theme
theme_set(theme_bw())

# ==============================================================================
# 1. DATA LOADING & PREPARATION
# ==============================================================================
message("Loading Data...")

# 1.1 Pollen Load & Gut Content Data
pollen_load_guts_24 <- read.csv(file.path("data", "pollen_load_and_guts_2024_Succisa_pratensis.csv"))

# 1.2 Pollen Deposition Data (from package)
data("pollen_deposition", package = "HanPolNet")

# Pre-processing: Create unique plant_id grouping
pollen_deposition <- pollen_deposition %>%
    mutate(
        # Create a unique plant_id using inflorescence_id + day
        # This correctly groups stigmas from the same plant/inflorescence on the same day
        plant_id = paste(year, inflorescence_id, day, sep = "_")
    )

# Remove rows with NA values in conspecific_pollen or heterospecific_pollen
pollen_deposition <- subset(pollen_deposition, (!is.na(conspecific_pollen)) & (!is.na(heterospecific_pollen)))

summary(pollen_deposition)
table(pollen_deposition$year)
length(unique(pollen_deposition$plant_id))


# 1.3 Interaction Data (Succisa specific)
interaction_data_Succisa_22_24 <- get_interaction_data(
    years = c(22, 23, 24),
    plant_species = "Suc_pra",
    is_pollinator = TRUE,
    remove_zeros = TRUE,
    standardize = TRUE
)

# 1.4 Interaction Data (Whole Community for context)
interaction_data_all_22_24 <- get_interaction_data(
    years = c(22, 23, 24),
    is_pollinator = TRUE,
    remove_zeros = TRUE,
    standardize = TRUE
)

# 1.5 Plant Abundance Data (Standardized)
plant_abundance_22_24 <- get_plant_data(
    years = c(22, 23, 24),
    output = "standardized"
)
# Note: Standardization details:
# Sublot Counts / 64 -> Proportion
# Stalk Counts / Max(Dataset) -> Relative Abundance

# 1.6 Single Visit Deposition (SVD) Data
SVD_Succisa_22_24 <- read.csv("data/SVD_Succisa_pratensis.csv")

# 1.7 Plot Coordinates (HanPolNet)
# Assuming 'hanpolnet_plots' comes from the package or is loaded in environment
if (!exists("hanpolnet_plots")) {
    # Placeholder if not in package, but typically is
    # data("hanpolnet_plots", package = "HanPolNet")
    # Or creating a mockup if needed for review logic
}


# ==============================================================================
# SECTION S: SUPPLEMENTARY DIAGNOSTICS
# ==============================================================================
# Before running main analyses, we verify model assumptions and data distributions.

message("Running Supplementary Diagnostics...")

# ------------------------------------------------------------------------------
# S1. Data Distribution Check
# ------------------------------------------------------------------------------
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
print(p_dist)


# ------------------------------------------------------------------------------
# S2. Variance Partitioning Model Diagnostics (Transformation Check)
# ------------------------------------------------------------------------------
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



# ------------------------------------------------------------------------------
# S3. Model Selection Diagnostics (Linear vs Exponential)
# ------------------------------------------------------------------------------
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


# ------------------------------------------------------------------------------
# S4. Slope Comparison Diagnostics
# ------------------------------------------------------------------------------
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
# 2. MAIN ANALYSES
# ==============================================================================

# ------------------------------------------------------------------------------
# 2.1 Pollinator Spectra Composition (Analysis of Stability)
# ------------------------------------------------------------------------------
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
message("Analyzing Pollinator Spectra...")

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

# (Visualization code omitted for brevity as this is an analysis script,
#  but the dataframe 'species_grouped' contains the result)
print(head(species_grouped))


# ------------------------------------------------------------------------------
# 2.2 Functional Form Analysis (Linear vs Exponential Test)
# ------------------------------------------------------------------------------
# Formal test to decide if the relationship is Type 1 (Linear) or Type 3 (Exponential)

test_curve_shape <- function(year_data, year_label) {
    # Aggregate
    agg_data <- year_data %>%
        group_by(plant_id) %>%
        summarise(
            mean_HP = mean(heterospecific_pollen, na.rm = TRUE),
            mean_CP = mean(conspecific_pollen, na.rm = TRUE),
            .groups = "drop"
        )

    # Models
    fit_linear <- lm(mean_HP ~ mean_CP, data = agg_data)
    fit_exp <- tryCatch(
        {
            nls(mean_HP ~ a * exp(b * mean_CP),
                data = agg_data,
                start = list(a = max(agg_data$mean_HP, na.rm = TRUE), b = -0.01)
            )
        },
        error = function(e) {
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

    # Comparison
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

message("Result of Functional Form Test:")
res_curve <- rbind(
    test_curve_shape(subset(pollen_deposition, year == 2022), "2022"),
    test_curve_shape(subset(pollen_deposition, year == 2023), "2023"),
    test_curve_shape(subset(pollen_deposition, year == 2024), "2024")
)
print(res_curve)


# ------------------------------------------------------------------------------
# 2.3 Slope Showdown (Aggregated Data Analysis)
# ------------------------------------------------------------------------------
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
fit_sqrt <- lm(sqrt(mean_HP) ~ mean_CP * Year, data = aggregated_data)

# ANOVA results
print(anova(fit_sqrt))

# Pairwise Compariasons of Slopes
slopes_em <- emtrends(fit_sqrt, pairwise ~ Year, var = "mean_CP")
print(slopes_em$emtrends) # Slope estimates
print(slopes_em$contrasts) # Comparisons


# ------------------------------------------------------------------------------
# 2.4 Daily Stability Test (2024 Data)
# ------------------------------------------------------------------------------
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
print(anova(fit_daily))
# Result Interpretation:
# The interaction term (mean_CP:as.factor(day)) is not significant (p = 0.366),
# and the main effect of day is also non-significant (p = 0.197).
# This confirms that the relationship between CP and HP deposition does not
# vary significantly day-to-day. The micro-scale stabilization holds reliable
# throughout 6 days of 2024 despite any behavioral shifts
# or minor weather fluctuations.


# ------------------------------------------------------------------------------
# 2.5 Variance Partitioning (VCA)
# ------------------------------------------------------------------------------
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
print(res_vca_hp)

# Run for CP    
res_vca_cp <- run_twopart_vca(vca_data, "sqrt_CP", "Conspecific Pollen (Sq)")
print(res_vca_cp)


# Define factor levels
all_results <- rbind(res_vca_hp, res_vca_cp)
all_results$level <- factor(all_results$level, levels = c("Year", "Date", "Plant", "Stigma"))

# Ensure the Metric names match the desired target strings before forcing them to factors
all_results$Metric <- dplyr::case_when(
    grepl("Heterospecific", all_results$Metric) ~ "Heterospecific pollen",
    grepl("Conspecific", all_results$Metric) ~ "Conspecific pollen",
    TRUE ~ all_results$Metric
)
all_results$Metric <- factor(all_results$Metric, levels = c("Heterospecific pollen", "Conspecific pollen"))

# 4. Visualization (Percent only)
p_var <- ggplot(all_results, aes(x = Metric, y = percent, fill = level)) +
    geom_bar(stat = "identity", width = 0.6) +
    facet_wrap(~Part) +
    scale_fill_brewer(palette = "Set2") +
    geom_text(aes(label = ifelse(percent > 1.5, paste0(round(percent, 0), "%"), "")),
        position = position_stack(vjust = 0.5),
        size = 4,
        fontface = "bold",
        color = "black"
    ) +
    labs(
        title = "Variance Partitioning (Transformed Data) of pollen deposited on stigmas",
        y = "% of Total Variance",
        x = "",
        fill = "Variance Source"
    ) +
    theme_classic() +
    theme(
        axis.text.x = element_text(face = "bold", angle = 0, hjust = 0.5, size = 11),
        strip.text = element_text(size = 12, face = "bold"),
        legend.position = "bottom"
    )

print(p_var)

# ------------------------------------------------------------------------------
# 2.6 Single Visit Deposition (SVD) Analysis
# ------------------------------------------------------------------------------
# Comparing efficiency (CP) and messiness (HP) across morphogroups.

message("Running SVD Analysis...")
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

# Filter for sufficient N
group_counts_svd <- SVD_clean %>%
    count(morphogroup) %>%
    filter(n >= 5)
SVD_final <- SVD_clean %>% filter(morphogroup %in% group_counts_svd$morphogroup)

# Kruskal-Wallis Tests
cat("Kruskal-Wallis CP:\n")
print(kruskal.test(conspecific_pollen ~ morphogroup, data = SVD_final))
cat("Kruskal-Wallis HP:\n")
print(kruskal.test(heterospecific_pollen ~ morphogroup, data = SVD_final))


# ------------------------------------------------------------------------------
# 2.7 Pollen Purity & CV Analysis
# ------------------------------------------------------------------------------
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

cv_gut <- pollen_load_guts_24 %>%
    summarise(
        CP = sd(suc_pra_guts, na.rm = TRUE) / mean(suc_pra_guts, na.rm = TRUE) * 100,
        HP = sd(other_pollen_guts, na.rm = TRUE) / mean(other_pollen_guts, na.rm = TRUE) * 100
    ) %>%
    mutate(Compartment = "Gut")

cv_table <- bind_rows(cv_stigma, cv_body, cv_gut)
print(cv_table)




# ------------------------------------------------------------------------------
# 2.8 Community Stability (Morisita-Horn)
# ------------------------------------------------------------------------------
message("Calculating Community Stability (Morisita-Horn)...")

# Prepare Community Matrix
community_matrix <- interaction_data_Succisa_22_24 %>%
    filter(!is.na(year)) %>%
    group_by(year, pollinator_id) %>%
    summarise(abundance = sum(rate, na.rm = TRUE), .groups = "drop") %>%
    pivot_wider(names_from = pollinator_id, values_from = abundance, values_fill = 0)

comm_mat <- as.matrix(community_matrix[, -1])
rownames(comm_mat) <- paste0("20", community_matrix$year)

# Calculate Similarity
mh_dist <- vegdist(comm_mat, method = "horn")
mh_sim <- 1 - as.matrix(mh_dist)
print(mh_sim)


# ------------------------------------------------------------------------------
# 2.9 Final Summary Table Generation
# ------------------------------------------------------------------------------
# Generates the master table (Table 4/5 in MS) summarizing all metrics by year.

message("Generating Final Summary Table...")

calc_net_metrics <- function(year_val, data) {
    target_year <- if (year_val > 2000) year_val - 2000 else year_val
    yr_data <- data %>% filter(year == target_year | year == year_val)
    if (nrow(yr_data) == 0) {
        return(data.frame(Year = year_val, H2 = NA, Succisa_d = NA, Succisa_H = NA))
    }

    # Identify columns dynamically
    pol_col <- names(yr_data)[names(yr_data) %in% c("pollinator_id", "pollinator_species", "pollinator")][1]
    plant_col <- names(yr_data)[names(yr_data) %in% c("plant_code", "plant_species", "plant_id")][1]
    int_col <- names(yr_data)[names(yr_data) %in% c("rate", "interaction_count", "interaction")][1]

    # Matrix
    web_matrix <- tryCatch(
        {
            mat <- yr_data %>%
                select(Plant = all_of(plant_col), Pollinator = all_of(pol_col), Interaction = all_of(int_col)) %>%
                mutate(Interaction = as.numeric(unlist(Interaction))) %>%
                pivot_wider(names_from = Pollinator, values_from = Interaction, values_fill = 0) %>%
                tibble::column_to_rownames("Plant") %>%
                as.matrix()
            mat
        },
        error = function(e) NULL
    )

    if (is.null(web_matrix)) {
        return(data.frame(Year = year_val, H2 = NA, Succisa_d = NA, Succisa_H = NA))
    }

    # Metrics
    h2 <- bipartite::H2fun(web_matrix)[1]
    d_vals <- bipartite::specieslevel(web_matrix, index = "d", level = "lower")
    suc_row <- rownames(d_vals)[rownames(d_vals) %in% c("Suc_pra", "Succisa pratensis")][1]

    if (!is.na(suc_row)) {
        succisa_d <- d_vals[suc_row, "d"]
        suc_int <- web_matrix[suc_row, ]
        succisa_H <- vegan::diversity(suc_int, index = "shannon")
    } else {
        succisa_d <- NA
        succisa_H <- NA
    }
    return(data.frame(Year = year_val, H2 = h2, Succisa_d = succisa_d, Succisa_H = succisa_H))
}

# 1. Network Metrics
net_metrics <- do.call(rbind, lapply(c(2022, 2023, 2024), calc_net_metrics, data = interaction_data_all_22_24))

# 2. Slopes
dep_model <- lm(sqrt(heterospecific_pollen) ~ conspecific_pollen * as.factor(year), data = pollen_deposition)
slopes_df <- as.data.frame(emtrends(dep_model, pairwise ~ year, var = "conspecific_pollen")$emtrends) %>%
    mutate(Year = as.numeric(as.character(year))) %>%
    select(Year, Slope = conspecific_pollen.trend)

# 3. Mean HP
hp_means <- pollen_deposition %>%
    group_by(year) %>%
    summarise(Mean_HP = mean(heterospecific_pollen, na.rm = TRUE), .groups = "drop") %>%
    mutate(Year = as.numeric(as.character(year)))

# 4. Abundance
plant_summary <- plant_abundance_22_24 %>%
    pivot_longer(cols = -c(year, plot_id), names_to = "Species", values_to = "Abundance") %>%
    group_by(year) %>%
    summarise(
        Succisa_Abundance = mean(Abundance[Species %in% c("Suc_pra", "Succisa pratensis")], na.rm = TRUE),
        Total_Abundance = sum(Abundance, na.rm = TRUE),
        .groups = "drop"
    ) %>%
    mutate(Year = as.numeric(as.character(year))) %>%
    mutate(Year = if_else(Year < 100, Year + 2000, Year))

# Combine
final_table <- net_metrics %>%
    left_join(slopes_df, by = "Year") %>%
    left_join(hp_means, by = "Year") %>%
    left_join(plant_summary, by = "Year")

print(final_table)

message("Analysis Script Complete!")
