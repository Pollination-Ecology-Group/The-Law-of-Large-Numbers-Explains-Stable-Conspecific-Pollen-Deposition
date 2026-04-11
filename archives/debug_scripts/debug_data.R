
# Load libraries
if (!require("devtools")) install.packages("devtools", repos="http://cran.us.r-project.org")
if (!require("HanPolNet")) {
    devtools::install("local_packages/HanPolNet", upgrade = "never")
    library(HanPolNet)
}

# 1. Interaction Data
cat("\n--- Interaction Data ---\n")
interaction_data_all_22_24 <- get_interaction_data(
    years = c(22, 23, 24),
    is_pollinator = TRUE,
    remove_zeros = TRUE,
    standardize = TRUE
)
print(head(interaction_data_all_22_24))
print(names(interaction_data_all_22_24))

# 2. Plant Abundance Data
cat("\n--- Plant Abundance Data ---\n")
plant_abundance_22_24 <- get_plant_data(
    years = c(22, 23, 24),
    output = "standardized"
)
print(head(plant_abundance_22_24))
print(names(plant_abundance_22_24))
