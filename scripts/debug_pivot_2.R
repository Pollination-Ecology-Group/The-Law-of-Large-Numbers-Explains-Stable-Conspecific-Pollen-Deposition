library(dplyr)
library(tidyr)
library(HanPolNet)

interaction_data_Succisa_22_24 <- get_interaction_data(
    years = c(22, 23, 24),
    plant_species = "Suc_pra",
    is_pollinator = TRUE,
    remove_zeros = TRUE,
    standardize = TRUE
)

wide <- interaction_data_Succisa_22_24 %>%
    dplyr::select(year, plot_id, pollinator_id, rate) %>%
    tidyr::pivot_wider(names_from = pollinator_id, values_from = rate, values_fill = 0, values_fn = function(x) sum(x, na.rm = TRUE))

cat("Structure of wide:\n")
str(wide)
