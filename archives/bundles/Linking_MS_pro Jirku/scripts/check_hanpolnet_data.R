if (!require("HanPolNet")) {
    devtools::install("local_packages/HanPolNet", upgrade = "never")
    library(HanPolNet)
}

data("pollen_deposition", package = "HanPolNet")

print("Column names:")
print(names(pollen_deposition))

print("Head of data:")
print(head(pollen_deposition))

print("Structure:")
str(pollen_deposition)
