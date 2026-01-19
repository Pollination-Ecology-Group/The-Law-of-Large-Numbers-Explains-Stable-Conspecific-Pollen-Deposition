# Setup Script for Collaborators

# 1. Restore standard dependencies from renv.lock
if (!requireNamespace("renv", quietly = TRUE)) install.packages("renv")
renv::restore()

# 2. Install the local HanPolNet package
# This package is bundled in the project because it is not available on CRAN
install.packages("./local_packages/HanPolNet", repos = NULL, type = "source")

message("Setup complete! You can now render the project.")
