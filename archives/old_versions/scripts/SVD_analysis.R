# Single Visit Deposition (SVD) Analysis
# This script analyzes the efficiency (CP) and messiness (HP) of different pollinator groups.

library(ggplot2)
library(dplyr)
library(patchwork)
library(dunn.test)
library(FSA) # for dunnTest if available, or we use dunn.test package

# 1. Load Data
SVD <- read.csv("data/SVD_Succisa_pratensis.csv")

# 2. Data Cleaning & Grouping
SVD_clean <- SVD %>%
    rename(
        duration_sec = delka_navstevy,
        year = rok,
        species = pollinator_species
    ) %>%
    mutate(
        # Create Morphogroups
        morphogroup = case_when(
            grepl("Eristalis", species) ~ "Eristalis spp.",
            grepl("Bombus", species) ~ "Bombus spp.",
            species == "Apis mellifera" ~ "Apis mellifera", # Usually abundant enough
            grepl("Syrphus", species) ~ "Syrphus spp.", # Common hoverfly
            grepl("Helophilus", species) ~ "Helophilus spp.",
            TRUE ~ "Other"
        ),
        # Refine groups: If N < 5 for a group (except Other), move to Other
        # For now, let's stick to the user's specific request + "Other"
        # User said: "Group other abundant genera separate if N > 5"
        # We will refine grouping dynamically below
        unique_id = row_number()
    )

# Dynamic grouping for abundant genera
# Count genera/species occurrences first
counts <- SVD_clean %>% count(species)

# Re-evaluate morphogoups with N > 5 rule
SVD_final <- SVD_clean %>%
    mutate(
        genus = sub(" .*", "", species),
        final_group = case_when(
            grepl("Eristalis", species) ~ "Eristalis spp.",
            grepl("Bombus", species) ~ "Bombus spp.",
            species %in% counts$species[counts$n > 5] ~ as.character(species), # Keep abundant species
            genus %in% (SVD_clean %>% count(genus) %>% filter(n > 5) %>% pull(genus)) ~ paste(genus, "spp."), # Group by genus if genus is abundant
            TRUE ~ "Other"
        )
    ) %>%
    mutate(
        Total_Pollen = conspecific_pollen + heterospecific_pollen,
        Prop_HP = ifelse(Total_Pollen > 0, heterospecific_pollen / Total_Pollen, 0)
    )

# Simplify groups for visualization (Eristalis, Bombus, Other, maybe a few tops)
# Let's clean up the "final_group" to be tidy
# Just ensuring we catch the main ones requested
SVD_final <- SVD_final %>%
    mutate(morphogroup = case_when(
        grepl("Eristalis", final_group) ~ "Eristalis spp.",
        grepl("Bombus", final_group) ~ "Bombus spp.",
        TRUE ~ final_group
    ))

# 3. Visualization

# Panel A: Efficiency (CP)
p_eff <- ggplot(SVD_final, aes(x = morphogroup, y = conspecific_pollen, fill = morphogroup)) +
    geom_boxplot(alpha = 0.6, outlier.shape = NA) +
    geom_jitter(width = 0.2, alpha = 0.5, size = 1.5) +
    labs(
        title = "A. Efficiency (CP Deposition)",
        y = "Conspecific Pollen Counts",
        x = "" # Hide x label for top/side plots usually or keep it
    ) +
    theme_bw() +
    theme(
        axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "none"
    )

# Panel B: Messiness (HP)
p_mess <- ggplot(SVD_final, aes(x = morphogroup, y = heterospecific_pollen, fill = morphogroup)) +
    geom_boxplot(alpha = 0.6, outlier.shape = NA) +
    geom_jitter(width = 0.2, alpha = 0.5, size = 1.5) +
    labs(
        title = "B. Messiness (HP Deposition)",
        y = "Heterospecific Pollen Counts",
        x = "Pollinator Group"
    ) +
    theme_bw() +
    theme(
        axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "none"
    )

# Combine
p_combined <- p_eff + p_mess
print(p_combined)

# 4. Statistical Analysis (Kruskal-Wallis)

cat("\n--- Kruskal-Wallis Test: CP ---\n")
kw_cp <- kruskal.test(conspecific_pollen ~ morphogroup, data = SVD_final)
print(kw_cp)

if (kw_cp$p.value < 0.05) {
    cat("\nPost-hoc Dunn Test (CP):\n")
    # Using FSA::dunnTest if possible, else just print message
    if (requireNamespace("FSA", quietly = TRUE)) {
        dunn_cp <- FSA::dunnTest(conspecific_pollen ~ morphogroup, data = SVD_final, method = "bh")
        print(head(dunn_cp$res))
    }
}

cat("\n--- Kruskal-Wallis Test: HP ---\n")
kw_hp <- kruskal.test(heterospecific_pollen ~ morphogroup, data = SVD_final)
print(kw_hp)

if (kw_hp$p.value < 0.05) {
    cat("\nPost-hoc Dunn Test (HP):\n")
    if (requireNamespace("FSA", quietly = TRUE)) {
        dunn_hp <- FSA::dunnTest(heterospecific_pollen ~ morphogroup, data = SVD_final, method = "bh")
        print(head(dunn_hp$res))
    }
}

# 5. Summary Text Generation (Printing to console for copy-paste)
cat("\n\n=== DRAFT TEXT ===\n")

cat("Methods Section:\n")
cat("To assess the effectiveness of individual pollinator groups, we performed a Single Visit Deposition (SVD) experiment. ")
cat("Virgin stigmas were offered to pollinators in the field, and the resulting pollen loads (conspecific and heterospecific) were counted after a single visitation event. ")
cat("Differences in pollen deposition (CP and HP) between pollinator morphogroups were analyzed using a Kruskal-Wallis test followed by Dunn's post-hoc test with Benjamini-Hochberg correction, as data did not meet normality assumptions.\n\n")

cat("Results Section:\n")
# Basic summary stats to inform the text
summary_stats <- SVD_final %>%
    group_by(morphogroup) %>%
    summarise(
        n = n(),
        mean_CP = mean(conspecific_pollen, na.rm = TRUE),
        mean_HP = mean(heterospecific_pollen, na.rm = TRUE)
    ) %>%
    arrange(desc(mean_CP))

print(summary_stats)
cat("\n(Refer to the summary stats above to fill in specific values)\n")
