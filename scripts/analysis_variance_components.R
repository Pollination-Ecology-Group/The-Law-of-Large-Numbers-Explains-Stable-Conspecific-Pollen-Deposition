# Variance Component Analysis of Heterospecific Pollen Deposition
# Purpose: Estimate the proportion of variance explained by Year, Date, Plant, and Stigma (Residual)

library(lme4)
library(dplyr)
library(ggplot2)
library(HanPolNet)

# 1. Load Data
# We access the data from the package as done in the manuscript
data("pollen_deposition", package = "HanPolNet")

# Prepare data: Create nested IDs and ensure correct data types
pollen_deposition <- pollen_deposition %>%
    mutate(
        # Create columns to match user's formula (1 | year / date / plant_id)
        date = as.factor(day),
        plant_id = paste(year, inflorescence_id, day, sep = "_")
    )

# 2. Fit Mixed Model (intercept-only)
# Hierarchical structure: Year / Date / Plant
# Syntax: (1 | year) + (1 | year:date) + (1 | year:date:plant_id) OR explicitly nested syntax
# The user suggested: (1 | year / date / plant_id)
# This expands to: (1 | year) + (1 | year:date) + (1 | year:date:plant_id)
# Note: 'date' in the formula refers to the column name. Nested syntax assumes factors are NOT unique.
# Since we have Year, Day, Inflorescence_ID...
# We will use the explicit nesting syntax requested by the user.

model_vca <- lmer(heterospecific_pollen ~ 1 + (1 | year / date / plant_id),
    data = pollen_deposition
)

# 3. Extract Variance Components
vc <- VarCorr(model_vca)
vc_df <- as.data.frame(vc)

# 4. Process Results
# Calculate total variance and percentages
total_variance <- sum(vc_df$vcov)

results <- vc_df %>%
    select(grp, vcov) %>%
    mutate(
        percent_variance = (vcov / total_variance) * 100,
        level = case_when(
            grp == "plant_id:date:year" ~ "Plant",
            grp == "date:year" ~ "Date",
            grp == "year" ~ "Year",
            grp == "Residual" ~ "Stigma (Residual)",
            TRUE ~ grp
        )
    )

# Print tabular results
print("Variance Component Analysis Results:")
print(results)

# 5. Visualization
# Stacked bar chart
p_vca <- ggplot(results, aes(x = "Variance Decomposition", y = percent_variance, fill = level)) +
    geom_bar(stat = "identity", width = 0.5) +
    scale_fill_brewer(palette = "Set2") +
    geom_text(aes(label = paste0(round(percent_variance, 1), "%")),
        position = position_stack(vjust = 0.5)
    ) +
    labs(
        title = "Variance Decomposition: Heterospecific Pollen Deposition",
        y = "% of Total Variance",
        x = "",
        fill = "Hierarchical Level"
    ) +
    theme_minimal() +
    theme(
        axis.text.x = element_blank(),
        axis.ticks.x = element_blank()
    )

# Save the plot
ggsave("variance_decomposition_plot.png", plot = p_vca, width = 6, height = 8)
print("Plot saved to variance_decomposition_plot.png")
