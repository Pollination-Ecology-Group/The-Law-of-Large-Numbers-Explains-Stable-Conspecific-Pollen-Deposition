
# Diagnostic Script with Sink

# Hardcoded output file
outfile <- "/home/meow/ownCloud - Mgr Jakub Štenc Phd@owncloud.cesnet.cz/Psani_clanku/2025/Linking-Network-Structure-to-Pollen-Deposition-Mechanisms/debug_sink.txt"
sink(outfile)

cat("START_DEBUG\n")

if (!require("devtools")) install.packages("devtools", repos="http://cran.us.r-project.org")
if (!require("HanPolNet")) {
    devtools::install("local_packages/HanPolNet", upgrade = "never")
    library(HanPolNet)
}

tryCatch({
    interaction_data_all_22_24 <- get_interaction_data(
        years = c(22, 23, 24),
        is_pollinator = TRUE,
        remove_zeros = TRUE,
        standardize = TRUE
    )
    cat("Data Loaded. Rows:", nrow(interaction_data_all_22_24), "\n")
    
    cat("Colnames:", paste(names(interaction_data_all_22_24), collapse=", "), "\n")
    cat("Years:", paste(names(table(interaction_data_all_22_24$year)), collapse=", "), "\n")
    
    # Check for Succisa names
    plant_cols <- c("plant_species", "plant_id", "plant")
    found_plant <- intersect(plant_cols, names(interaction_data_all_22_24))
    if(length(found_plant) > 0) {
        pcol <- found_plant[1]
        cat("Plant Column:", pcol, "\n")
        
        all_plants <- unique(interaction_data_all_22_24[[pcol]])
        cat("Unique Plants (first 50):", paste(head(sort(all_plants), 50), collapse=", "), "\n")
        
        # Check specifically for Succisa
        targets <- c("Succisa pratensis", "Suc_pra", "Succisa_pratensis")
        matches <- targets[targets %in% all_plants]
        cat("Succisa Matches:", paste(matches, collapse=", "), "\n")
    }

}, error = function(e) {
    cat("ERROR:", e$message, "\n")
})

cat("END_DEBUG\n")
sink()
