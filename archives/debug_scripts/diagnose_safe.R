
# Safe Debug Script

# 1. Test Write
writeLines("Hello from R", "hello.txt")

# 2. Extract Data Info
if (!require("devtools")) install.packages("devtools", repos="http://cran.us.r-project.org")
if (!require("HanPolNet")) {
    devtools::install("local_packages/HanPolNet", upgrade = "never")
    library(HanPolNet)
}

tryCatch({
    data <- get_interaction_data(
        years = c(22, 23, 24),
        is_pollinator = TRUE,
        remove_zeros = TRUE,
        standardize = TRUE
    )
    
    info <- c(
        paste("Rows:", nrow(data)),
        paste("Cols:", paste(names(data), collapse=", ")),
        paste("Years:", paste(names(table(data$year)), collapse=", "))
    )
    
    # Check Plant
    pcols <- intersect(c("plant_species", "plant_id", "plant"), names(data))
    if(length(pcols)>0){
        pcol <- pcols[1]
        info <- c(info, paste("Plant Col:", pcol))
        info <- c(info, paste("Sample Plants:", paste(head(unique(data[[pcol]]), 10), collapse=", ")))
        
        # Check Succisa
        if("Succisa pratensis" %in% data[[pcol]]) info <- c(info, "FOUND: Succisa pratensis")
        if("Suc_pra" %in% data[[pcol]]) info <- c(info, "FOUND: Suc_pra")
    }
    
    writeLines(info, "data_info.txt")

}, error = function(e){
    writeLines(paste("ERROR:", e$message), "error_log.txt")
})
