# Debugging ID Construction
library(dplyr)
library(stringr)

# Load data directly from CSV
SVD_Suc_pra <- read.csv(file.path("data", "SVD_Succisa_pratensis.csv"))

pollen_deposition <- SVD_Suc_pra %>%
    rename(year = rok) %>%
    mutate(
        date = as.POSIXct(cas_navstevy, format = "%m/%d/%Y %H:%M:%S"),
        day = format(date, "%d-%m")
    )

print("Head of pollen_deposition$id:")
print(head(pollen_deposition$id, 20))

# Re-create plant_id logic
# Check what 'id' looks like
ids <- head(pollen_deposition$id, 20)
plant_ids_old <- str_sub(ids, end = -3)
plant_ids_new <- paste(str_sub(ids, end = -3), head(pollen_deposition$day, 20), sep = "_")

print("Mapping Old Logic:")
print(data.frame(id = ids, plant_id_old = plant_ids_old, plant_id_new = plant_ids_new))

# Check counts on full data
pollen_deposition$plant_id_old <- str_sub(pollen_deposition$id, end = -3)
pollen_deposition$plant_id_new <- paste(str_sub(pollen_deposition$id, end = -3), pollen_deposition$day, sep = "_")

print("Total rows:")
print(nrow(pollen_deposition))

print("Unique IDs:")
print(length(unique(pollen_deposition$id)))

print("Unique Plant IDs (New logic):")
print(length(unique(pollen_deposition$plant_id_new)))

# Check aggregation count
agg_data <- pollen_deposition %>%
    group_by(year, plant_id_new) %>%
    summarise(
        mean_HP = mean(heterospecific_pollen, na.rm = TRUE),
        mean_CP = mean(conspecific_pollen, na.rm = TRUE),
        .groups = "drop"
    )

print("Rows in aggregated data:")
print(nrow(agg_data))
print(table(agg_data$year))
