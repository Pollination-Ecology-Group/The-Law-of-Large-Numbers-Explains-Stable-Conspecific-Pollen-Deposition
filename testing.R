# 1. Get interaction data
interaction_data_Succisa_22_24 <- get_interaction_data(
    years = c(22, 23, 24),
    plant_species = "Suc_pra",  # Changed from "Succisa_pratensis"
    is_pollinator = TRUE,
    remove_zeros = TRUE,
    standardize = TRUE
)interaction_data_Succisa_22_24
