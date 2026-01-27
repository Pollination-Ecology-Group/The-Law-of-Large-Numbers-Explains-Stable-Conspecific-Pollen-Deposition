# Mover Script: Reorganize Project Files
# Run this once in your R console to organize files into data/ and output/ directories.

# 1. Check & Create Directories
dirs <- c("data", "output", "images")
for (d in dirs) {
    if (!dir.exists(d)) {
        dir.create(d)
        message(paste("Created directory:", d))
    } else {
        message(paste("Directory exists:", d))
    }
}

# 2. Move Data Files
# Identify common data files in root (exclude those already in subdirs)
data_exts <- c("csv", "xlsx", "txt", "rds")
# Use regex to match extensions at end of string
data_pattern <- paste0("\\.(", paste(data_exts, collapse = "|"), ")$")

files <- list.files(path = ".", pattern = data_pattern, full.names = FALSE)
# Exclude specific files if necessary (e.g. strict system files, though exclusions usually generic)
# Ensure we don't move files that are incorrectly named or system artifacts if possible
files <- files[!grepl("^\\.", files)] # Exclude dotfiles like .RData logic if they matched (extensions above don't match RData)

for (f in files) {
    new_path <- file.path("data", f)
    if (!file.exists(new_path)) {
        file.rename(from = f, to = new_path)
        message(paste("Moved", f, "to", new_path))
    } else {
        message(paste("Skipped", f, "- already exists in data/"))
    }
}

# 3. Move Outputs
output_exts <- c("html", "docx", "pdf")
output_pattern <- paste0("\\.(", paste(output_exts, collapse = "|"), ")$")

out_files <- list.files(path = ".", pattern = output_pattern, full.names = FALSE)

for (f in out_files) {
    # Safety: Skip README (often stays in root)
    if (grepl("^README", f, ignore.case = TRUE)) next

    new_path <- file.path("output", f)
    if (!file.exists(new_path)) {
        file.rename(from = f, to = new_path)
        message(paste("Moved", f, "to", new_path))
    } else {
        message(paste("Skipped", f, "- already exists in output/"))
    }
}

message("File organization complete.")
