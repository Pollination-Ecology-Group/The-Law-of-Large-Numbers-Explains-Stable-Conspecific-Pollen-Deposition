# Data and code for: The law of large numbers explains stable conspecific pollen deposition

Jakub Štenc, Martin Freudenfeld, Petr Švanda, Eva Matoušková, Tadeáš Ryšan, Helena Pijálková, Jiří Hadrava, Michael Mikát, Eva Horčičková, Zdeněk Janovský

Contact: Jakub Štenc (jakub.stenc@natur.cuni.cz), Department of Botany, Faculty of Science, Charles University, Prague, Czech Republic

## Study

Field data on pollination of *Succisa pratensis* collected in August 2022, 2023 and 2024 at the site "K Handrkovu" near Vernýřov, Central Bohemia, Czech Republic (49.8466° N, 15.1498° E). The data include pollen deposited on terminal-stage stigmas, single-visit deposition experiments, pollen carried on flower visitors, plant–pollinator interactions and flowering plant abundance recorded in a grid of permanent plots. Methods are described in the article.

## Contents

```
README.md
data/
  pollen_deposition.csv
  SVD_Succisa_pratensis.csv
  pollen_load_and_guts_2024_Succisa_pratensis.csv
  interaction_data_all_22_24.csv
  interaction_data_Succisa_22_24.csv
  plant_abundance_22_24.csv
  plant_species_codes.csv
  plot_coordinates.csv
scripts/
  Analysis_FML_Z.R           all analyses and figures of the main text
images/                      photographs and icons used in the figures
Supplementary_Material.qmd   analyses and tables of the Supplementary Data
renv.lock                    R package versions used
```

All files are comma-separated, UTF-8 encoded. Missing values are `NA` or empty.

## Reproducing the analyses

Analyses were run in R 4.3.3. From the top folder of this archive (so that the `data/` paths resolve):

```r
install.packages("renv")
renv::restore()                       # installs the package versions in renv.lock
source("scripts/Analysis_FML_Z.R")    # main analyses and figures
```

The Supplementary Data can be rebuilt with `quarto render Supplementary_Material.qmd --to html`.

## Variables

### `pollen_deposition.csv`
Pollen on terminal-stage stigmas (flowers with senesced or absent corolla). One row per stigma; 714 stigmas, of which 693 have pollen counts and were analysed (the others were damaged during preparation).

| Variable | Description |
|---|---|
| id | Stigma identifier |
| inflorescence_id | Inflorescence (plant) from which the stigma was collected; up to three stigmas per inflorescence |
| plant_species | Always *Succisa pratensis* |
| conspecific_pollen | Number of *S. pratensis* pollen grains on the stigma |
| heterospecific_pollen | Number of pollen grains of other species on the stigma |
| pollen_total | conspecific_pollen + heterospecific_pollen |
| year | Year of collection |
| day | Day of collection in August |

### `SVD_Succisa_pratensis.csv`
Single-visit deposition: pollen deposited on a previously bagged, virgin stigma during the first visit of a flower visitor. One row per visit (124 visits).

| Variable | Description |
|---|---|
| id | Sample identifier |
| plant_species | Always *Succisa pratensis* |
| type | Always `SVD` |
| conspecific_pollen | *S. pratensis* pollen grains deposited during the visit |
| heterospecific_pollen | Pollen grains of other species deposited during the visit |
| pollinator_species | Visitor taxon |
| behaviour_during_visit | `nectar_feeding`, `pollen_feeding` or `walked_by` |
| visit_duration_s | Duration of the visit (s) |
| visit_datetime | Date and time of the visit (MM/DD/YYYY hh:mm:ss) |
| pollinator_sex | `male`, `female` or `NA` |
| year | Year |

### `pollen_load_and_guts_2024_Succisa_pratensis.csv`
Flower visitors caught on *S. pratensis* in 2024. Pollen was swabbed from one half of the body (left or right, chosen at random) with fuchsin jelly; gut contents were examined separately. One row per insect (300 insects). Only the body pollen counts (`suc_pra_load`, `other_pollen_load`) are used in the article.

| Variable | Description |
|---|---|
| id | Insect identifier |
| time, date | Time and date of capture |
| year | Year (2024) |
| plant_species | Plant on which the insect was caught (*S. pratensis*) |
| sex | `F` or `M` |
| wing_wear | Wing wear score, 0 (none) to 4 |
| gut_fullness | Gut fullness score, 0 (empty) to 4 |
| ovaries | Ovary development score, 0 to 4 (females) |
| pollinator_species | Insect taxon |
| network_species | Taxon group used in network analyses |
| id_sample_guts | Gut sample identifier |
| suc_pra_guts | *S. pratensis* pollen grains in the gut |
| other_pollen_guts | Pollen grains of other species in the gut |
| id_pollen_load | Body pollen sample identifier |
| suc_pra_load | *S. pratensis* pollen grains on half of the body |
| other_pollen_load | Pollen grains of other species on half of the body |

### `interaction_data_all_22_24.csv` and `interaction_data_Succisa_22_24.csv`
Flower visitors touching the reproductive organs of flowering plants in the permanent plots, recorded during repeated surveys of up to five minutes per plot (07:00–19:00). The first file covers all plant species, the second only *S. pratensis*. One row per plant–visitor record.

| Variable | Description |
|---|---|
| sampling_id | Survey (one plot visit) identifier |
| year | Year, two digits (22, 23, 24) |
| month, day, hour, minute | Date and time of the survey |
| plot_id | Permanent plot; see `plot_coordinates.csv` |
| plant_code | Plant species code; see `plant_species_codes.csv` |
| plant_name | Plant species name |
| pollinator_id | Visitor taxon as recorded in the field |
| interaction_count | Number of visitor individuals recorded |
| experiment_run | Sampling campaign (e.g. `Handrkov24_VIII` = August 2024) |
| sex | Visitor sex as recorded in the field (not used in the analyses) |
| shade | Shading of the plot as recorded in the field, in mixed formats (not used in the analyses) |
| verified | Whether the taxon identification was verified |
| is_pollinator | Whether the taxon is treated as a pollinator |
| network_species | Taxon group used in the analyses |
| order | Insect order of the visitor |
| family, genus, notes | Empty in this version |
| n_visits | Number of surveys of the plot in the given campaign (sampling effort) |
| rate | interaction_count / n_visits |

A few rows (14 in the community file, 3 in the *S. pratensis* file) contain only missing values and are ignored in the analyses.

### `plant_abundance_22_24.csv`
Flowering plant abundance per plot and year (mean of two surveys per campaign). Each plot was divided into 64 cells. Values are standardised: for species recorded as presence/absence per cell the value is the proportion of occupied cells; for species whose flowering stalks were counted it is the count divided by the maximum count in the dataset. `stalk_counted` in `plant_species_codes.csv` says which method applies.

| Variable | Description |
|---|---|
| year | Year, two digits (22, 23, 24) |
| plot_id | Permanent plot |
| other columns | One column per plant species code (see `plant_species_codes.csv`) |

### `plant_species_codes.csv`

| Variable | Description |
|---|---|
| plant_code | Species code used in the other files |
| plant_name | Scientific name |
| stalk_counted | 1 = flowering stalks counted; 0 = presence/absence per cell recorded |

### `plot_coordinates.csv`

| Variable | Description |
|---|---|
| plot_id | Permanent plot |
| sector | Part of the site (local name) |
| x_relative_m, y_relative_m | Position on the local site grid (m) |
| edge_plot | TRUE for 10 additional plots at the edge of the site; the 93 plots with FALSE are those used in the article |
| longitude, latitude | Plot position, WGS84 (EPSG:4326) |

## Licence

Data: CC BY 4.0. Code: MIT.

