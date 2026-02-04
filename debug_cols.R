
# Debug Column Names
if (!require("devtools")) install.packages("devtools", repos="http://cran.us.r-project.org")
if (!require("HanPolNet")) {
    devtools::install("local_packages/HanPolNet", upgrade = "never")
    library(HanPolNet)
}

interaction_data_all_22_24 <- get_interaction_data(
    years = c(22, 23, 24),
    is_pollinator = TRUE,
    remove_zeros = TRUE,
    standardize = TRUE
)

cat("Columns in interaction_data_all_22_24:\n")
print(names(interaction_data_all_22_24))

# Also check raw output of a single year
cat("\nSample Data (Head):\n")
print(head(interaction_data_all_22_24))
