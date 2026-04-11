# Linking Network Structure to Pollen Deposition Dynamics
Jakub Štenc

# Introduction

Pollen deposited on stigmas is the ultimate outcome of pollination
interactions. However, the relationship between **who visits**
(pollinator network structure) and **what lands on the stigma** (pollen
deposition) remains poorly understood.

While some studies have observed annual variations in pollinator sharing
and heterospecific pollen (HP) receipt, we currently lack a mechanistic
explanation linking the *network structure* (who visits) to the
*deposition outcome* (what lands on the stigma).

Arceo-Gómez et al. ([2016](#ref-arceo2016patterns)) provided a
conceptual framework suggesting that the shape of the relationship
between Conspecific Pollen (CP) and Heterospecific Pollen (HP) on
stigmas can reveal insights about the pollinator assemblage’s structure.
In their study, Arceo-Gómez et al. ([2016](#ref-arceo2016patterns))
argue that intraspecific variation in pollen receipt is not random. By
plotting HP against CP for individual flowers, two distinct patterns
typically emerge. These patterns act as a signature of the pollinator
community structure.

**I propose we test a hypothesis derived from** Arceo-Gómez et al.
([2016](#ref-arceo2016patterns)) : that the shape of the relationship
between Conspecific Pollen (CP) and Heterospecific Pollen (HP) on
individual stigmas is determined by the **evenness** and **quality** of
the pollinator assemblage. We utilize a dataset covering both
**pollinator visitation networks** and **stigmatic pollen loads** for
*Succisa pratensis* across three years (2022–2024).

# The Conceptual Framework

Arceo-Gómez et al. (2016) argue that intraspecific variation in pollen
receipt is not random. By plotting HP against CP for individual flowers,
two distinct patterns typically emerge. These patterns act as a
signature of the pollinator community structure.

## Scenario A: The “Generalist” Assemblage (Type 1)

If the pollinator assemblage is **even** (many generalists contributing
similarly), we expect **Type 1** dynamics. These visitors carry mixed
loads; therefore, as they deposit more CP, they inevitably deposit more
HP.

- **Pattern:** Linear positive relationship.

- **Ecological Driver:** High pollinator evenness; generalized
  interactions.

## Scenario B: The “Specialist/Uneven” Assemblage (Type 3)

If the assemblage is **uneven** (dominated by a few high-quality
specialists and some “messy” low-quality generalists), we expect **Type
3** dynamics. High-quality pollinators deposit pure CP (high CP, low
HP), while incidental visitors deposit mostly HP (low CP, high HP).

- **Pattern:** Exponential decrease (or “L” shape).

- **Ecological Driver:** Low pollinator evenness; high variation in
  pollinator quality.

## Methods

### Pollen deposited on stigmas

### Data analysis

Full metadata, variable definitions, and summary statistics for the
datasets used in this study are available in the [Data
Dictionary](https://www.google.com/search?q=data_dictionary.html).

## Results

<details class="code-fold">
<summary>Code</summary>

``` r
ggplot(pollen_deposition, aes(x = conspecific_pollen, y = heterospecific_pollen, color = as.factor(year))) +
    geom_point(alpha = 0.5) +
    geom_smooth(method = "loess", se = FALSE, size = 1.2) + # Smoothed trend line
    theme_minimal() +
    labs(x = "Conspecific Pollen", y = "Heterospecific Pollen", color = "Year")
```

</details>

<img
src="MS_Succisa_deposition_files/figure-commonmark/unnamed-chunk-1-1.png"
data-fig-align="center"
alt="Visualizing the CP-HP relationship. Look for linear increases vs. exponential decays." />

<details class="code-fold">
<summary>Code</summary>

``` r
pollen_deposition <- pollen_deposition[!is.na(pollen_deposition$heterospecific_pollen), ] # Remove rows with NA in heterospecific_pollen

pollen_deposition$plant_id <- str_sub(pollen_deposition$id, end = -3) # Extract plant ID from stigma ID

model_linear_mixed <- lme(
    heterospecific_pollen ~ conspecific_pollen * year, # Fixed effect: conspecific pollen and year
    random = ~ 1 | plant_id, # This tells R: "Group stigmas by inflorescence"
    data = pollen_deposition
)

summary(model_linear_mixed)
```

</details>

<details class="code-fold">
<summary>Code</summary>

``` r
test_curve_shape <- function(year_data, year_label) {
    # 1. Fit Linear Model (Type 1)
    fit_linear <- lm(heterospecific_pollen ~ conspecific_pollen, data = year_data)

    # 2. Fit Exponential Model (Type 3)
    fit_exp <- tryCatch(
        {
            nls(heterospecific_pollen ~ a * exp(b * conspecific_pollen),
                data = year_data,
                start = list(a = max(year_data$heterospecific_pollen), b = -0.01)
            )
        },
        error = function(e) NULL
    )

    # 3. Compare AIC
    aic_lin <- AIC(fit_linear)
    aic_exp <- if (!is.null(fit_exp)) AIC(fit_exp) else NA

    return(data.frame(
        Year = year_label,
        Linear_AIC = round(aic_lin, 2),
        Exp_AIC = round(aic_exp, 2),
        Best_Fit = ifelse(!is.na(aic_exp) && aic_exp < (aic_lin - 2), "Exponential (Type 3)", "Linear (Type 1)")
    ))
}

# Run the test
results_2022 <- test_curve_shape(subset(pollen_deposition, year == 2022), "2022")
results_2023 <- test_curve_shape(subset(pollen_deposition, year == 2023), "2023")
results_2024 <- test_curve_shape(subset(pollen_deposition, year == 2024), "2024")

# Display Results
knitr::kable(rbind(results_2022, results_2023, results_2024), caption = "Model Comparison Results")
```

</details>

| Year | Linear_AIC | Exp_AIC | Best_Fit        |
|:-----|-----------:|--------:|:----------------|
| 2022 |     765.44 |  773.08 | Linear (Type 1) |
| 2023 |     930.86 |      NA | Linear (Type 1) |
| 2024 |    4052.84 |      NA | Linear (Type 1) |

Model Comparison Results

``` r
suc_pra_222324 <- get_interaction_data(
    plant_species = "Suc_pra",
    start_time = "7:00",
    end_time = "18:00",
    remove_zeros = TRUE,
    standardize = TRUE
)
```

``` r
ggplot(pollen_load_guts_24, aes(x = suc_pra_load, y = other_pollen_load, color = as.factor(pollinator_species))) +
    geom_point(alpha = 0.5) +
    theme_minimal() +
    labs(x = "Conspecific Pollen", y = "Heterospecific Pollen", color = "Pollinator species")
```

![](MS_Succisa_deposition_files/figure-commonmark/unnamed-chunk-5-1.png)

``` r
ggplot(pollen_load_guts_24, aes(x = suc_pra_guts, y = other_pollen_guts, color = as.factor(pollinator_species))) +
    geom_point(alpha = 0.5) +
    theme_minimal() +
    labs(x = "Conspecific Pollen", y = "Heterospecific Pollen", color = "Pollinator species")
```

![](MS_Succisa_deposition_files/figure-commonmark/unnamed-chunk-6-1.png)

``` r
ggplot(SVD_Suc_pra, aes(x = conspecific_pollen, y = heterospecific_pollen, color = as.factor(pollinator_species))) +
    geom_point(alpha = 0.5) +
    theme_minimal() +
    labs(x = "Conspecific Pollen", y = "Heterospecific Pollen", color = "Pollinator species")
```

![](MS_Succisa_deposition_files/figure-commonmark/unnamed-chunk-7-1.png)

# Proposed Analysis

We can test this hypothesis because we have independent datasets for
both the **curve** (pollen counts) and the **driver** (visitation
networks).

## Step 1: Characterize the CP-HP Curve (2022-2024)

For each year of *Succisa* data, we will fit two models to the stigmatic
pollen counts:

1.  Linear Model (HP∼CP)

2.  Non-linear/Exponential Model (HP∼a⋅eb⋅CP)

We will determine if the relationship changed between 2022, 2023, and
2024. For example, did 2024 (which showed lower HP in preliminary
results) shift from a Type 1 to a Type 3 curve?

## Step 2: Calculate Pollinator Evenness

Using our “snapshot” network data (97,000+ interactions), we will
calculate **Simpson’s Evenness** specifically for the sub-network of
visitors to *Succisa pratensis* for the corresponding years.

## Step 3: The Link

We will test if years (or plots) with **Type 1 (Linear)** pollen curves
correspond to years with **higher pollinator evenness** in the
visitation data.

# Why This Matters

This moves our analysis beyond simple abundance (“we found less HP”) to
**functional mechanisms**.

If we confirm that *Succisa* fits a **Type 3** curve in years with low
evenness, it suggests that “pollinator sharing” (a network metric) does
not translate linearly to pollen deposition. It would prove that the
*identity* and *quality* of specific visitors shield the plant from
heterospecific pollen interference, even when surrounded by
heterospecific neighbors.

# Next Steps

1.  **Data Prep:** I will merge the pollen count CSVs with the
    plot-level IDs.

2.  **Modelling:** I will run the `nls` (non-linear least squares) and
    `lm` models in R for the three years.

3.  **Network Metrics:** I will extract the specific visitor diversity
    indices for *Succisa* from the `HanPolNet` pipeline.

## Discussion

## References

<div id="refs" class="references csl-bib-body hanging-indent">

<div id="ref-arceo2016patterns" class="csl-entry">

Arceo-Gómez, G., L. Abdala-Roberts, A. Jankowiak, C. Kohler, G. A.
Meindl, C. M. Navarro-Fernández, V. Parra-Tabla, et al. 2016. Patterns
of among-and within-species variation in heterospecific pollen receipt:
The importance of ecological generalization. *American Journal of
Botany* 103: 396–407.

</div>

</div>
