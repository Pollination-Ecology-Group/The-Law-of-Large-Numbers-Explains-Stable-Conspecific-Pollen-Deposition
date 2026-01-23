if (!require("HanPolNet")) {
    library(devtools)
    install("local_packages/HanPolNet", upgrade = "never")
    library(HanPolNet)
}
data("pollen_deposition", package = "HanPolNet")

# Check 2024 structure
dat_24 <- subset(pollen_deposition, year == 2024)

print("Unique days in 2024:")
print(unique(dat_24$day))

print("Unique Inflorescence IDs in 2024:")
print(length(unique(dat_24$inflorescence_id)))

print("Total rows 2024:")
print(nrow(dat_24))

# Check overlap of plants across days
print("Plant overlap table (head):")
print(head(table(dat_24$inflorescence_id, dat_24$day)))

# Check if inflorescence_id is unique per year or global?
print("Unique inflorescence_id total:")
print(length(unique(pollen_deposition$inflorescence_id)))
