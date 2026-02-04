
# Diagnostic Script for Interaction Data

# Load libraries and package (simulating the QMD environment)
if (!require("devtools")) install.packages("devtools", repos="http://cran.us.r-project.org")
if (!require("HanPolNet")) {
    devtools::install("local_packages/HanPolNet", upgrade = "never")
    library(HanPolNet)
}

# 1. Load Data
mess <- tryCatch({
    interaction_data_all_22_24 <- get_interaction_data(
        years = c(22, 23, 24),
        is_pollinator = TRUE,
        remove_zeros = TRUE,
        standardize = TRUE
    )
    "Data Loaded Successfully"
}, error = function(e) paste("Error loading data:", e$message))

print(mess)

if (exists("interaction_data_all_22_24")) {
    cat("\n--- Structure ---\n")
    str(interaction_data_all_22_24)
    
    cat("\n--- Column Names ---\n")
    print(colnames(interaction_data_all_22_24))
    
    cat("\n--- Year Table ---\n")
    if("year" %in% names(interaction_data_all_22_24)) {
        print(table(interaction_data_all_22_24$year))
    } else {
        cat("Column 'year' NOT found.\n")
    }
    
    cat("\n--- Plant Names (First 20 unique) ---\n")
    # Try to guess plant column
    plant_cols <- c("plant_species", "plant_id", "plant")
    found_plant <- intersect(plant_cols, names(interaction_data_all_22_24))
    if(length(found_plant) > 0) {
        print(head(unique(interaction_data_all_22_24[[found_plant[1]]]), 20))
    } else {
        cat("No obvious plant column found.\n")
    }

} else {
    cat("Dataframe was not created.\n")
}
