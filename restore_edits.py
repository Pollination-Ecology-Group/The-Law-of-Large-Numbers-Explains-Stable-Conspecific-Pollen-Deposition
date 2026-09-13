import re

with open('MS_FML.qmd', 'r') as f:
    text = f.read()

# 1. Add \ before chunks with fig-cap or tbl-cap
# First, insert \ before every ```{r} that has a fig-cap or tbl-cap
def insert_backslash(match):
    chunk = match.group(0)
    if '#| fig-cap:' in chunk or '#| tbl-cap:' in chunk or 'flextable' in chunk:
        return '\\ \n\n' + chunk
    return chunk

text = re.sub(r'```\{r\}.*?\n```', insert_backslash, text, flags=re.DOTALL)

# 2. Add (@fig-spatial-temporal-abundance)
text = text.replace(
    'did not differ significantly between years.',
    'did not differ significantly between years (@fig-spatial-temporal-abundance).'
)

# 3. Add #| results: hide to fig-spatial-temporal-abundance
text = text.replace(
    '#| message: false\n#| fig-height: 12\n#| fig-width: 12\n```',
    '#| message: false\n#| results: hide\n#| fig-height: 12\n#| fig-width: 12\n```'
)

# 4. Remove fig-slope-showdown and its header
text = re.sub(r'### Total Pollen Deposition \(TPD\)\n\n```\{r\}\n#\| label: fig-slope-showdown.*?```\n\n', '', text, flags=re.DOTALL)

# 5. Add flextable to monte-carlo-svd
# First remove the old monte-carlo-svd chunk if it exists
text = re.sub(r'```\{r\}\n#\| label: monte-carlo-svd.*?```', '', text, flags=re.DOTALL)

# Now find the place to insert it (after the text ending in "suppressing it back toward the mechanical minimum.")
new_table_text = """**Table 1. Monte Carlo simulation validation for interannual conspecific (CP) and heterospecific (HP) pollen accumulation. The table details the estimated required visitation rates, observed versus simulated mean pollen loads, and structural divergence metrics (Kolmogorov-Smirnov D-statistics, corresponding p-values, and Overlapping Coefficients) across the three study years (2022–2024).**

\\ 

```{r}
#| label: monte-carlo-svd
#| echo: false
#| warning: false
#| message: false
flextable(ks_results) %>%
    set_header_labels(
        Year = "Year",
        Estimated_Visits = "Estimated\\nVisits",
        Obs_Mean_CP = "Observed\\nMean CP",
        Sim_Mean_CP = "Simulated\\nMean CP",
        KS_CP_D = "CP K-S\\n(D)",
        KS_CP_p = "CP K-S\\n(p)",
        OVL_CP = "CP Overlap\\n(%)",
        Obs_Mean_HP = "Observed\\nMean HP",
        Sim_Mean_HP = "Simulated\\nMean HP",
        KS_HP_D = "HP K-S\\n(D)",
        KS_HP_p = "HP K-S\\n(p)",
        OVL_HP = "HP Overlap\\n(%)"
    ) %>%
    theme_vanilla() %>%
    set_table_properties(layout = "autofit", width = 1) %>%
    fontsize(size = 9, part = "all") %>%
    align(align = "center", part = "all")
```"""

text = text.replace(
    'toward the mechanical minimum.',
    'toward the mechanical minimum.\n\n' + new_table_text
)

# 6. Remove "and as part of the Supplementary Material."
text = text.replace(
    "[URL TO BE ADDED] and as part of the Supplementary Material.",
    "[URL TO BE ADDED]."
)

# 7. Add Authors' contributions and Supplementary Material text
supp_text = """## Authors' contributions 


## Acknowledgements

This research was supported by the Czech Science Foundation (grant No. 23-06433S). We extend our gratitude to Dr. Jan Klečka for their constructive feedback on earlier drafts of this manuscript and help with the script. We also thank the students and field assistants from the Department of Botany, Charles University, for their assistance in sample collection.

## Supplementary Material

The supplementary material provides extended methodological details and results, including:

* **Model Diagnostics (Sections S1–S3)**: Transformation diagnostics and selection criteria for the variance component analyses.
* **Sampling Summaries (Tables S1–S3)**: Comprehensive counts of raw pollinator abundances, single-visit deposition events, and body pollen load samples.
* **Statistical Outputs (Tables S8–S10)**: Detailed results for hierarchical variance partitioning and significance testing.
* **Dataset Metadata (Table S6)**: Complete data dictionary for the published datasets.

## References
"""

# Replace everything from "## Acknowledgements" downwards
text = re.sub(r'## Acknowledgements.*', supp_text, text, flags=re.DOTALL)

with open('MS_FML.qmd', 'w') as f:
    f.write(text)

print("Done")
