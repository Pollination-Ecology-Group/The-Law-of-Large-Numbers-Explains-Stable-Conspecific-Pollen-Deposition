# File Organization Script
# This script creates standard folders and moves files into them.

# 1. Define Standard Folders
folders <- c("data", "output", "scripts", "images")

# 2. Create Folders if they don't exist
for (dir in folders) {
    if (!dir.exists(dir)) {
        dir.create(dir)
        message(paste("Created directory:", dir))
    } else {
        message(paste("Directory already exists:", dir))
    }
}

# 3. Move Files

# Helper function to move files safely
move_file <- function(from, to) {
    if (file.exists(from)) {
        file.rename(from, file.path(to, basename(from)))
        message(paste("Moved:", from, "->", to))
    }
}

# Move Image Files (*.jpg, *.png) to images/
image_files <- list.files(pattern = "\\.(jpg|png|jpeg)$", ignore.case = TRUE)
# Exclude variance_decomposition_plot.png if it should be in output/ or images/? Let's put in images/
for (f in image_files) {
    move_file(f, "images")
}

# Move Data Files (*.csv, *.xlsx) to data/
# Be careful not to move files already in data/ (recursive=FALSE default for list.files covers this if we stay in root)
data_files <- list.files(pattern = "\\.(csv|xlsx)$", ignore.case = TRUE)
for (f in data_files) {
    # If file is not in a subdirectory (list.files checks root unless recursive=T)
    # But wait, list.files returns just names in current dir.
    # Check if we are moving the script itself or anything critical? No, script is .R
    move_file(f, "data")
}

# Move Output Files (*.html, *.docx) to output/
# Exclude .Rmd, .qmd files
output_files <- list.files(pattern = "\\.(html|docx|pdf)$", ignore.case = TRUE)
# Keep README.md and other MDs? Yes.
# Keep Rplots.pdf? Maybe junk, but move to output.
for (f in output_files) {
    if (!grepl("^README\\.md$", f) && !grepl("^data_dictionary.qmd$", f) && !grepl("^MS_Succisa_deposition.qmd$", f) && !grepl("^Supplementary_Material.qmd$", f)) {
        move_file(f, "output")
    }
}

# Move R Scripts (*.R) to scripts/
r_scripts <- list.files(pattern = "\\.R$", ignore.case = TRUE)
for (f in r_scripts) {
    # Don't move the script itself if we are running it?
    # Actually we are writing to scripts/organize_project.R, so it's already there.
    # But if we run this from root, it might see other .R files.
    # We should move setup.R, check_species.R etc.
    if (basename(f) != "organize_project.R") { # Skip self if present in root (it won't be)
        move_file(f, "scripts")
    }
}

message("File organization complete!")
