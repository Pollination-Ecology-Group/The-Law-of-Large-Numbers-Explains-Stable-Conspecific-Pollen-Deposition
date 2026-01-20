
library(HanPolNet)
library(dplyr)
library(sf)

data("hanpolnet_plots")
data("plant_abundance")

print("HanPolNet Plots IDs:")
print(sort(unique(hanpolnet_plots$plot_id)))

print("Plant Abundance IDs (cols):")
# Check how plot_id is stored in plant_abundance
print(head(plant_abundance$plot_id))

# Try extraction again
print("Testing extraction:")
test_ids <- unique(hanpolnet_plots$plot_id)
extracted <- as.numeric(gsub("plot_", "", test_ids))
print(data.frame(orig=test_ids, extracted=extracted))
