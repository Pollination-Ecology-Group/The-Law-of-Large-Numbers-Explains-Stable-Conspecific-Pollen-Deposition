library(devtools)
load_all("local_packages/HanPolNet")
library(dplyr)

# 1. Load Data
pollen_load_guts_24 <- read.csv(file.path("data", "pollen_load_and_guts_2024_Succisa_pratensis.csv"))
interaction_data_Succisa_22_24 <- get_interaction_data(
    years = c(22, 23, 24),
    plant_species = "Suc_pra",
    is_pollinator = TRUE,
    remove_zeros = TRUE,
    standardize = TRUE
)

# 2. Get Species Lists
sp_interaction <- unique(interaction_data_Succisa_22_24$pollinator_id)
sp_loads <- unique(pollen_load_guts_24$pollinator_species)

# 3. Print
print("Species in Interaction Data:")
print(sort(sp_interaction))
print("Species in Pollen Load/Gut Data:")
print(sort(sp_loads))
print("Intersection:")
print(intersect(sp_interaction, sp_loads))
