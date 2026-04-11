
# Debug Column Types
outfile <- "debug_types_out.txt"
sink(outfile)

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
    
    cat("Data Rows:", nrow(data), "\n")
    cat("--------------------------------------------------\n")
    sapply(names(data), function(n) {
        cat(n, ":", class(data[[n]]), "\n")
    })
    cat("--------------------------------------------------\n")
    
    # Specific check for potential interaction columns
    int_cols <- c("rate", "interaction_count", "interaction", "count")
    for(col in int_cols) {
        if(col %in% names(data)) {
            val_chk <- data[[col]]
            cat("Column:", col, "\n")
            cat("  Class:", class(val_chk), "\n")
            cat("  Is list?", is.list(val_chk), "\n")
            cat("  Any NA?", any(is.na(val_chk)), "\n")
            cat("  Head:", paste(head(val_chk), collapse=", "), "\n")
        }
    }

}, error = function(e) {
    cat("ERROR:", e$message, "\n")
})

sink()
