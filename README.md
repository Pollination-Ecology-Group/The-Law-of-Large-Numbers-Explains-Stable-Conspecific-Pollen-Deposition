# From Single Visit Stochasticity to Long-Term Stability of Pollen
Stigmatic Deposition:
Jakub Štenc

## Abstract

**Premise:** Pollen transfer by animal vectors is inherently stochastic
at the micro-scale, yet terminal deposition of conspecific pollen (CP)
often remains remarkably stable at the population level. It remains
unclear how plants compensate for the extreme variance in individual
pollinator visits to secure reliable CP receipt while simultaneously
mitigating heterospecific pollen (HP) accumulation from co-flowering
plants with shared pollinators.

**Methods:** Using a three-year dataset (2022–2024) for *Succisa
pratensis* in a system with well-known plant-pollinator interactions, we
evaluated pollen transfer dynamics across multiple hierarchical scales.
We combined variance partitioning of terminal pollen deposition (TPD) on
stigmas with single-visit deposition (SVD) experiments across pollinator
taxa. Furthermore, we performed Monte Carlo simulations using SVD and
visitation frequency data to reveal how pollen accumulation across
highly stochastic visits leads to relatively stable TPD.

**Results:** Variance partitioning revealed that temporal shifts
explained negligible variation in CP deposition; rather, the vast
majority of variance occurred at the micro-scale among individual
stigmas. SVD experiments confirmed that individual pollinator visits are
highly stochastic and inefficient. However, Monte Carlo simulations
demonstrated that at the whole-stigma level, the accumulation of pollen
across multiple visits effectively neutralises micro-scale
unpredictability, translating into stable terminal CP loads. In
contrast, HP accumulation proved to be substantially more variable and
partially depended on inter-annual variation in the floral
neighbourhood.

**Conclusions:** Despite the mechanical unpredictability of pollen
deposition during individual pollinator visits, plants can secure highly
stable conspecific pollen deposition through the simple accumulation of
pollen over the stigma lifespan. However, the potential for reproductive
interference via heterospecific pollen relies heavily on
context-dependent ecological traits.

## Introduction

Pollen transfer by animal vectors is inherently stochastic at the
micro-level (reviewed in [Minnaar et al., 2019](#ref-Minnaar2019)),
characterised by highly variable, heterogeneous pollen loads delivered
during individual foraging events ([Richards et al.,
2009](#ref-richards2009variation); [King et al., 2013](#ref-king2013)).
Yet, despite this fine-scale unpredictability, population-level studies
demonstrate that conspecific pollen (CP) deposition on stigmas can
remain remarkably stable across multiple years (e.g., [Fang et al.,
2019](#ref-fang2019multi), [2022](#ref-Fang2022)). This paradox
highlights a fundamental gap in pollination ecology: how do plants
compensate for the high variance in individual pollinator visits to
secure reliable CP receipt on their stigmas, while simultaneously
mitigating the accumulation of heterospecific pollen (HP) from other
plants within the co-flowering community?

To resolve this paradox, it is critical to examine pollen transfer
dynamics across hierarchical scales, from single-visit deposition (SVD)
to terminal pollen deposition (TPD). At the scale of an SVD, the
delivery of conspecific pollen is highly unpredictable, and pollen
transfer is markedly inefficient. Even among legitimate pollinators, the
quantity of pollen transferred fluctuates dramatically due to highly
variable individual pollen loads ([King et al., 2013](#ref-king2013);
[Freudenfeld et al., 2025](#ref-freudenfeld2025interannual)). This
micro-scale stochasticity is further compounded by taxon-specific
differences in pollinator behaviour, such as grooming ([Holmquist et
al., 2012](#ref-holmquist2012influence)), insect morphological traits
that drive pollen load composition ([Cullen et al.,
2021](#ref-cullen2021diversity)), complex pollen carryover dynamics
across successive flower visits ([Thomson and Plowright,
1980](#ref-thomson1980)), and fluctuating foraging decisions within the
plant-pollinator community ([Valdovinos,
2025](#ref-valdovinos2025effect)). Consequently, from the perspective of
an individual receptive stigma, the absolute number of CP grains
received during any single visit exhibits significant depositional
variance King et al. ([2013](#ref-king2013)), requiring plants to rely
on broader ecological mechanisms to aggregate these variable events into
a stable reproductive outcome ([Richards et al.,
2009](#ref-richards2009variation)).

To overcome the high unpredictability of individual visits, some plants
rely on high visitation rates, accumulating a sufficient volume of
visits to average out the extreme depositional variance of individual
vectors and ensure reliable CP receipt. The attraction of numerous
pollinators is often facilitated by dense local floral displays
([Vázquez, 2005](#ref-vazquez2005degree); [Janovský et al.,
2013a](#ref-janovsky2013conspecific)) and/or rich flowering communities
that draw diverse pollinator assemblages ([Venjakob et al.,
2016](#ref-venjakob2016plant); [Aguirre and Junker,
2024](#ref-aguirre2024floral)). However, accumulating pollinator visits
within a network concurrently introduces the risk of reproductive
interference in the form of HP received from other plant species sharing
pollinators within the community ([Morales and Traveset,
2008](#ref-morales2008interspecific),
[2013](#ref-morales2013heterospecific); [Arceo-Gómez and Ashman,
2011](#ref-ArceoGomez2011)). Co-flowering heterospecific neighbouring
plant species not only act as sources of HP, but they also potentially
alter the composition and fidelity of the pollinator assemblage visiting
the focal plant ([Lázaro et al., 2009](#ref-Lazaro2009); [Ye et al.,
2020](#ref-ye2020)). Thus, inter-annual changes in the co-flowering
plant community may alter pollinator composition and behaviour, leading
to both direct and indirect effects on CP and HP transfer. Therefore,
plants are under evolutionary pressure to secure stable CP delivery
while buffering against unpredictable pollinator behaviour. High
conspecific floral density may mitigate the proportion of deposited HP
by pulling pollinators from co-flowering neighbours ([Arceo-Gómez et
al., 2016](#ref-arceo2016patterns)), providing density-dependent
buffering.

Furthermore, density-dependent buffering can be significantly enhanced
by the temporal stratification of plant-pollinator interactions within
the community ([Stone et al., 1998](#ref-Stone1998); [Schwarz et al.,
2021](#ref-Schwarz2021)). For example, the diurnal pollen release
schedules previously observed in *Succisa pratensis* allow the plant to
establish temporal dominance early in the day ([Štenc et al.,
2023](#ref-stenc2023pollinator)). By releasing pollen and attracting
vectors before co-flowering competitors do, a plant can secure
substantial CP delivery prior to the accumulation of heterogeneous
pollen loads on shared vectors, functioning as a form of temporal
specialisation ([Brosi, 2016](#ref-Brosi2016)). This temporal
stratification ensures that the highest-frequency visits occur within a
specific time window, mitigating the subsequent accumulation of HP
([Schwarz et al., 2021](#ref-Schwarz2021); [Štenc et al.,
2023](#ref-stenc2023pollinator)).

While the variability of individual visits and the theoretical
frameworks for pollen accumulation are well known, empirical studies
rarely measure these processes across multiple scales in a natural
system to study them simultaneously. In this study, we evaluate pollen
transfer using a three-year dataset (2022–2024) for the highly visited
plant *Succisa pratensis*. We address the following objectives: (1) to
quantify the hierarchical variance in pollen deposition across years,
days, individual plants, and individual stigmas; (2) to compare the
mechanical efficiency of CP and HP transfer across dominant vector taxa
at the single-visit (SVD) scale; (3) to mathematically test whether
visitation redundancy drives stable CP deposition using Monte Carlo
simulations; and (4) to determine how year-to-year changes in local
conspecific floral abundance influence the accumulation of HP. We
hypothesise that despite the high variability of individual generalist
visits, *S. pratensis* achieves stable CP deposition because high local
floral abundance and early morning pollen release ([Štenc et al.,
2023](#ref-stenc2023pollinator), [2025](#ref-stenc2025pollen)) buffer
the plant against unpredictable single-visit deliveries.

## Methods

### Study system

Our observations were conducted in a semi-natural grassland community
characterised by a high abundance of flowering plants (especially
*Succisa pratensis*) and a diverse pollinator community dominated by
hoverflies. The study site, “K Handrkovu”, is located near the village
of Vernýřov, Central Bohemia, Czech Republic (49.8466° N, 15.1498° E).
The site can be classified as a mosaic of moist-to-mesophilic and
eutrophic-to-mesotrophic grasslands, supporting more than 50
entomogamous plant species that flower in late summer each year
([Janovský et al., 2013a](#ref-janovsky2013conspecific)). Fieldwork was
conducted from 2022 to 2024 during the peak of *S. pratensis* flowering
activity (15–19 August, 13–20 August, and 11–18 August, respectively).

*Succisa pratensis*, our focal plant species, maintains a relatively
large and stable population at our study site. It is frequently visited
by a wide spectrum of pollinators—especially hoverflies
(<a href="#fig-plant-pollinator-panel" class="quarto-xref">Figure 1</a>)—which
feed on both its pollen and nectar. Important traits related to its
pollination include distinctive open inflorescences accessible to most
pollinators, protandry to prevent self-pollination ([Bartoš et al.,
2020](#ref-bartos2020self)), and a diurnal pollen release schedule
occurring in the morning hours ([Štenc et al.,
2023](#ref-stenc2023pollinator)).

<div id="fig-plant-pollinator-panel">

![](MS_FML_files/figure-commonmark/fig-plant-pollinator-panel-1.png)

Figure 1: A) Stigma of *Succisa pratensis* with several pollen
morphotypes; B) Pollinator (*Eristalis* sp.) on a flower of *S.
pratensis*, highlighting pollen visible on the pollinator’s body; C)
Detail of an anther with visible pollen grains of *S. pratensis*; D)
Detail of a stigma of *S. pratensis* with visible deposited pollen
grains.

</div>

### Plant-Pollinator Interactions and Plant Abundance

Following the established protocol for this study locality ([Janovský et
al., 2013b](#ref-Janovsky2013)), we collected data on pollinator
visitation activity in 93 permanent plots arranged in a semi-regular
grid, spaced 20 m apart across the study site. All plots were
permanently marked with a metal nail, recovered using a metal detector,
and visibly marked prior to the sampling event each year. Within the
plots, we recorded flowering plant abundance and all interactions of
flower-visiting pollinators with flowering *S. pratensis*, as well as
with other plant species in the surrounding community. To avoid
pseudoreplication, all flowers within a plot were surveyed only once per
individual sampling event. All interactions occurring during the survey
moment were recorded, lasting up to five minutes per plot. Each plot was
surveyed at least twenty times during a sampling period spanning 5–10
consecutive days at the peak of flowering (mid-August) each year. For
this study, we utilised interactions recorded during the main diurnal
period of pollinator activity (07:00–19:00). We recorded only the
pollinators that made contact with the reproductive organs of the
visited plant, counting each individual pollinator only once. Finally,
we computed standardised interaction rates (total number of interactions
per plot survey) for pollinators visiting *S. pratensis* from 2022 to
2024, and compared the distribution of interaction rates for the
specific group of pollinators visiting *S. pratensis* against those
visiting all other plant species.

To determine plant abundance, we surveyed the plots twice during each
sampling event to control for potential phenological shifts; for this
study, we used the average plant abundance per sampling event. To record
abundance, we divided each plot into 64 individual cells using a string
grid gently placed over the plot. Within each cell, we either counted
the flowering stalks or recorded the presence/absence of flowering
plants, depending on the species.

### Pollen Load

In 2024, we investigated the number of pollen grains carried on the
pollinators’ bodies. Foraging pollinators visiting *S. pratensis*
inflorescences were captured with an entomological net and euthanised
immediately. Following Beattie ([1971](#ref-beattie1971technique)), we
swabbed pollen grains from one half of each pollinator’s body (randomly
selecting the left or right side) using a small block of Fuchsin jelly.
Captured pollinators were subsequently stored in 70% ethanol. On the
same day, we produced semi-permanent slides by melting the Fuchsin jelly
onto a microscope slide using a heating pad, adding a coverslip, and
sealing it with nail polish. We later counted and identified all pollen
grains using a light microscope, sorting them into conspecific *S.
pratensis* pollen and heterospecific pollen (HP) from other plant
species.

### Single-Visit Deposition (SVD)

To estimate the pollinator single-visit deposition (SVD), we followed
protocols adapted from previous studies ([King et al.,
2013](#ref-king2013); [Valverde et al., 2019](#ref-valverde2019)). To
prevent prior pollinator access, we enclosed selected inflorescences in
fine-mesh tulle bags before the plants entered the male phase and opened
their anthers. Once a plant entered the female phase with receptive
stigmas, we removed the bag and observed the inflorescence until the
arrival of the first pollinator. Pollinators were allowed to visit only
one flower within the inflorescence, after which we immediately
collected its stigma into a microcentrifuge tube containing 70% ethanol.
If a pollinator visited multiple flowers, we collected only the first
visited stigma and removed the others from the plant. The SVD
experiments were conducted in 2022, 2023 and 2024.

### Terminal Pollen Deposition (TPD) on Stigma

To determine terminal pollen deposition (TPD), we collected stigmas from
flowers with visibly senesced or absent corollas, indicative of the late
flowering stage (pers. obs.). Each year, we collected 3 randomly
selected stigmas per flowerhead to account for intra-inflorescence
variability, and from 30 randomly selected individuals from the
population per day. In 2022 and 2023, we collected samples during only
one day, in 2024 we sampled stigmas during 6 days, following the same 3
stigma per flowerhead and 30 plant individual design.

We placed the collected stigmas onto microscope slides and allowed the
ethanol to evaporate on a heating pad. Subsequently, we applied 1 µL of
10% KOH and allowed the samples to dry, followed by 3 µL of 3% hydrogen
peroxide. After another drying period, we added 13 µL of 8% acetic acid.
Once completely dry, we applied 5 µL of a dye solution (safranin, water,
and glycerol), covered the samples with a coverslip, applied gentle,
even pressure to squash the stigma, and sealed the edges with nail
polish to create semi-permanent samples. We discarded

### Statistical Analysis

All statistical analyses were performed in R (version 4.3.3; R Core Team
([2025](#ref-Rcore))). To systematically evaluate pollen transfer
dynamics across hierarchical scales, our analyses were structured into
four primary components: (1) community stability and visitation
dynamics, (2) single-visit transfer efficiency, (3) variance
partitioning of terminal pollen deposition (TPD), and (4) mathematical
simulations of visitation redundancy.

#### Community Stability and Visitation Dynamics

To assess the temporal consistency of the local ecological network, we
calculated the Morisita-Horn similarity index for both the pollinator
visitation spectra and the co-flowering plant community across the three
study years. Differences in standardised visitation rates (total
interactions per plot) and per-capita visitation rates (interactions per
focal plant) across years were analysed using Kruskal-Wallis rank-sum
tests, followed by post hoc Dunn’s tests with Benjamini-Hochberg false
discovery rate corrections. Furthermore, to formalise the
density-dependent dilution effect, we fitted a log-log linear regression
evaluating how per-capita visitation rates scaled with local *S.
pratensis* plot abundance.

#### Single-Visit Deposition (SVD)

To evaluate micro-scale mechanical transfer, pollinators were
categorised into dominant morpho-groups (e.g., *Eristalis* spp.,
*Helophilus* spp., *Bombus* spp.). Differences in both conspecific
pollen (CP) delivery and heterospecific pollen (HP) carryover during a
single visit were tested across these taxa using Kruskal-Wallis rank-sum
tests.

#### Variance Partitioning

To identify the exact spatial and temporal scales driving
unpredictability in terminal stigmatic pollen loads, we applied Variance
Components Analysis (VCA) using Linear Mixed Models (LMMs). Prior to
modelling, pollen counts were square-root transformed to stabilise
variance and approximate normality, as confirmed by residual diagnostic
plots (‘Residuals vs. Fitted’ and ‘Normal Q-Q’). Because fine-scale
daily data were exclusively available for the 2024 season, we
constructed two complementary LMMs to prevent rank deficiency: an
inter-annual model spanning 2022–2024 (`1 | year / plant_id`), and an
intra-annual model restricted to 2024 (`1 | date / plant_id`). The
statistical significance of these hierarchical random effects (Year,
Date, and Plant) was evaluated using Likelihood Ratio Tests.

Furthermore, to test how HP accumulation scales with CP receipt, and
whether this relationship shifted during the high-density anomaly of
2024, we aggregated pollen counts to the plant level. We fitted a linear
model testing the interaction between transformed CP and Year
(`sqrt(mean_HP) ~ sqrt(mean_CP) * Year`). Differences in the rates of HP
accumulation across years were subsequently quantified using pairwise
slope contrasts via estimated marginal means.

#### Monte Carlo Simulation of Visitation Redundancy

To test whether visitation redundancy mathematically drives stable
pollen deposition, we constructed a Monte Carlo bootstrapping
simulation. Because pollinator morphology and mechanical transfer
efficiency are functionally consistent traits, we pooled all
single-visit deposition (SVD) data across the three study years to
create a single, highly robust global pool of vector deposition
profiles. This allowed us to mathematically isolate the effect of the
plant’s changing floral density while holding vector baseline deposition
constant.

We parameterised the simulation independently for each study year
(2022–2024). For a given year, we estimated the average required
visitation rate by dividing the empirical mean of conspecific pollen
(CP) on that year’s stigmas by the mean CP of the global SVD pool. We
then generated 10,000 virtual stigmas per year, randomly sampling (with
replacement) from the global SVD pool based on that year’s specific
visitation rate.

Finally, we evaluated the fit of the simulated null models against our
true field observations. Because the large sample size of the simulation
(N = 10,000) renders traditional two-sample Kolmogorov-Smirnov (K-S)
p-values hypersensitive to trivial biological deviations—such as
physical stigma saturation limits—we focused on the K-S D-statistic to
quantify the maximum distributional divergence as a measure of effect
size. Furthermore, to provide a robust and intuitive measure of
simulation accuracy independent of sample size, we calculated the
Overlapping Coefficient (OVL; Pastore & Calcagnì, 2019). The OVL
quantifies the exact proportion of area shared between the empirical and
simulated probability density curves, providing a direct metric of
functional overlap between the theoretical null model and field reality.

## Results

Across the three-year study period (2022–2024), we collected and
analysed a total of 693 terminal-stage stigmas from 273 individual
*Succisa pratensis* plants to evaluate terminal pollen deposition (TPD).
We sampled 84 stigmas in 2022, 89 stigmas in 2023, and 520 stigmas in
2024, with collections conducted over 6 consecutive days. To quantify
micro-scale transfer dynamics and vector efficiency, we captured pollen
from **300** individual visitors of *S. pratensis* to assess body pollen
loads, and we sampled **124** controlled single-visit deposition (SVD)
events on virgin stigmas. Finally, we recorded **2998** individual
plant-pollinator interactions during standardised focal plot
observations. Detailed descriptions of the individual results follow.

### Coefficient of Variation and Variance Partitioning

To quantify the unpredictability of pollen transport, we compared the
Coefficient of Variation (CV) across functional transport compartments
(<a href="#fig-plots-2" class="quarto-xref">Figure 2</a>). Conspecific
pollen (CP) exhibited high variability on pollinator bodies (CV = 129%)
and in SVDs (CV = 206%). However, at the TPD stage, the variability
decreased considerably (CV = 69%). Conversely, heterospecific pollen
(HP) remained relatively variable across all compartments, from vector
bodies (CV = 264%) through to final stigmatic loads (CV = 147%). The
inter-annual variability of TPD remained relatively stable across years
for CP (CVs ranging from 66% to 73%), but the variability of HP
increased in 2024 (CV = 125%,
<a href="#fig-plots-2" class="quarto-xref">Figure 2</a>).

Hierarchical variance partitioning further confirmed the micro-scale
nature of this stochasticity in TPD (**?@fig-plots-3**). For CP,
temporal phenology (years and days) explained only a small proportion of
the variation; instead, the vast majority of depositional variance
occurred at the micro-spatial scale, driven by differences among
individual plants (15%) and individual stigmas (82%). Variance
partitioning and subsequent likelihood ratio tests revealed that HP
deposition was significantly driven by temporal shifts at the
macro-scale ($\chi^2 = 32.39, p < 0.001$) and by spatial variation among
individual plants nested within the year ($\chi^2 = 104.73, p < 0.001$).

Notably, intra-annual analysis of the 2024 season showed that daily
temporal variation was not a significant driver of either CP or HP
deposition ($\chi^2 = 1.32, p = 0.517$ for CP;
$\chi^2 = 0.19, p = 0.663$ for HP). Instead, variance during the 2024
season was heavily driven by differences among individual plants
($\chi^2 = 126.53, p < 0.001$), suggesting that plant-level traits or
highly localised micro-spatial effects dictate heterospecific pollen
transfer more than daily phenological shifts.

<div id="fig-plots-2">

Coefficient of Variation (CV) and Mean of Conspecific (CP) and
Heterospecific (HP) pollen counts. A–B) CV of pollen counts; C–D) Mean
pollen counts + SE.

Figure 2

</div>

### Pollen Load and Single-Visit Deposition (SVD)

To evaluate the mechanical efficiency of pollen transfer, we compared
the total pollen loads carried on vector bodies to the amounts of pollen
successfully deposited on stigmas during single-visit depositions (SVD).
Pollinators carried substantial pollen loads (Mean Body CP = 147.8 (SD =
393.6); Mean Body HP = 478.8 (SD = 1102.2)). However, per-visit
mechanical transfer was remarkably inefficient. Only a minute fraction
of the available body load, approximately 2.3% for CP and 0.1% for HP,
was successfully deposited onto a receptive stigma during a single
floral visit.

To determine if specific pollinator taxa drive the depositional variance
observed across the network, we compared single-visit depositions (SVD)
across the dominant floral visitor morphogroups (e.g., *Eristalis* spp.,
*Helophilus* spp., *Bombus* spp.). Kruskal-Wallis rank-sum tests
revealed no significant differences among pollinator taxa in the amount
of conspecific pollen deposited during a single visit
($H_3 = 1.59, p = 0.661$). Similarly, there were no significant
differences across taxa in the deposition of heterospecific pollen per
visit ($H_3 = 5.20, p = 0.158$). These results indicate that per-visit
pollen transfer efficiency and heterospecific pollen carryover may be
highly stochastic but functionally equivalent across the studied
pollinator morphogroups. Consequently, the terminal stigmatic pollen
loads received by *S. pratensis* are not dictated by the taxonomic
identity or morphological specialisation of its visitors, but purely by
the cumulative frequency of their visits.

### Pollinator Visitation Spectra and Co-flowering Community Stability

To assess the temporal stability of the pollinator visitation spectra of
*S. pratensis* and the co-flowering plant community, we compared species
composition across years using the Morisita-Horn similarity index
([Horn, 1966](#ref-horn1966measurement)). The pollinator spectra showed
high compositional overlap across the years, ranging from 0.78 to 0.96
similarity. The flowering plant community composition showed lower
overlap, ranging from 0.69 to 0.71 (**?@fig-community-stability**).

### Floral Density and Visitations

Despite the increase in *S. pratensis* abundance in 2024,
sampling-effort-standardised visitation rates per plot and per plant did
not differ significantly between years
(**?@fig-spatial-temporal-abundance**).

### TPD

### Monte Carlo Simulation: The Interannual Variance Filter

The year-by-year Monte Carlo simulation confirmed that visitation
redundancy effectively neutralises micro-scale stochasticity for
conspecific pollen (CP) across all measured years in the TPD. Regardless
of the study year, the random additive accumulation of SVDs from the
global vector pool successfully recreated the stable mean CP loads
observed in the field (e.g., 2024 Simulated CP Mean: 26.8; Observed CP
Mean: 27.4). While the two-sample K-S tests flagged mathematical
divergences ($p < 0.001$) due to the hypersensitivity of a
10,000-iteration model to biological saturation limits, the tight
convergence of the central tendencies and the functional overlap of the
distributions (D-statistics ranging from 0.103 to 0.166) demonstrate
that visitation frequency alone acts as a robust mathematical filter,
effectively translating single-visit variance into stable CP deposition.

Conversely, for heterospecific pollen (HP), the simulation’s accuracy
varied sharply between years, revealing that HP accumulation is governed
by environmental context rather than simple mechanical redundancy. If
generalist vectors deposit mixed pollen loads based strictly on their
baseline single-visit profiles, the null model dictates that stigmas
should accumulate a low, normalised baseline load of HP (3.4 to 4.5
grains). In standard-density years (2022 and 2023), empirical stigmas
accumulated HP loads that exceeded this mathematical expectation by more
than tenfold (e.g., 2023 Observed HP: 50.4 vs. Simulated: 3.4),
resulting in severe structural divergence from the null model
($D > 0.77$). Crucially, during the increased density of *S. pratensis*
in 2024, this neighbourhood-driven accumulation declined. The observed
HP dropped to 9.6 grains, forcing the empirical distribution
significantly closer to the mechanical baseline ($D = 0.265$). Because
vector mechanical efficiency was held constant in our simulation, this
interannual shift confirms that while standard-density years suffer
heavy reproductive interference from shared networks, the increased
conspecific floral abundance in 2024 actively mitigated HP accumulation,
suppressing it back toward the mechanical minimum.

## Discussion

Generalist pollination systems present a paradox: animal vectors are
inherently unpredictable at the micro-level ([Richards et al.,
2009](#ref-richards2009variation); [King et al., 2013](#ref-king2013)),
yet population-level pollen deposition often remains remarkably stable
([Fang et al., 2019](#ref-fang2019multi)). Our results demonstrate that
even plants subject to highly stochastic single-visit pollen delivery
can achieve stable terminal conspecific deposition. Specifically, our
analysis confirms that visitation redundancy mathematically neutralises
conspecific variance. However, this stabilising effect is asymmetric;
while conspecific pollen (CP) receipt is heavily buffered,
heterospecific pollen (HP) accumulation remains highly variable and
probably influenced by environmental fluctuations ([Arceo-Gómez et al.,
2016](#ref-arceo2016patterns)).

Crucially, our variance partitioning revealed how this asymmetry
functions across scales. CP receipt is stable against inter-annual
shifts due to interaction frequency, restricting variance in TPD almost
entirely to the individual stigmas and plants. Our Monte Carlo
simulation supports this mechanism, demonstrating that the statistical
law of large numbers naturally translates highly variable single visits
into guaranteed population-level CP stability. Conversely, HP
accumulation on *S. pratensis* stigmas was not successfully predicted by
the Monte Carlo simulation. This likely reflects the highly dynamic
behaviour of the pollinators, which is not accounted for in the
simulation; the amount of heterospecific pollen an insect deposits is
not a fixed mechanical baseline, but is dynamically changing by the
previous visits to the surrounding co-flowering plants and the local
floral density of the focal plant at the exact time of the visit ([Ye et
al., 2020](#ref-ye2020)).

Our single-visit deposition (SVD) analysis revealed no significant
differences in CP or HP transfer across the dominant pollinator taxa; a
single visit from a *Bombus* was functionally indistinguishable from a
visit by an *Eristalis* syrphid fly (**?@fig-body-svd** C). While
failing to detect differences between morphological groups may be caused
by insufficient sampling, the high stochasticity of individual visits
may play a more significant role in pollen deposition than the
morphological traits of the visitors. Consequently, highly stochastic
pollen delivery poses a potentially high risk for plant reproduction
([Richards et al., 2009](#ref-richards2009variation)). In the case of
*S. pratensis*, this risk is mitigated by the high visitation rates we
observed, which provides reproductive assurance and may maximise the
genetic diversity of pollen donors. Because *S. pratensis* possesses
only a single ovule, successful fertilisation theoretically requires
only one viable grain. However, accumulating CP loads that vastly exceed
this minimum requirement shifts the reproductive bottleneck from the
pollinator’s body to the plant’s stigmas. As highlighted by Minnaar et
al. ([2019](#ref-Minnaar2019)), such high-volume deposition triggers
intense pollen-pollen competition. Consequently, high pollen deposition
possibly serves as a mechanism to collect pollen from various donors,
allowing for selection based on pollen quality ([Hildesheim et al.,
2019](#ref-hildesheim2019quantitative); [Madjidian et al.,
2020](#ref-madjidian2020direct)).

However, while the deposition of CP remains relatively stable across
years, HP deposition exhibits high year-to-year variability
(<a href="#fig-plots-2" class="quarto-xref">Figure 2</a> B),
highlighting the high unpredictability of HP and its potential negative
impact on plant reproduction. Our results underscore that, unlike the
mathematically determined stability of CP, HP deposition is highly
context-dependent. The extent of heterospecific contamination is likely
dictated by a complex, shifting interplay of co-flowering phenology,
relative neighbourhood abundances, and active pollinator foraging
decisions at the exact time of visitation ([Ye et al.,
2020](#ref-ye2020)). In years with dense heterospecific neighbourhoods,
the attractive pull of co-flowering competitors alters the fidelity of
shared vectors ([Morales and Traveset,
2008](#ref-morales2008interspecific); [Flanagan et al.,
2010](#ref-flanagan2022pollinator)), driving interspecific transitions
and increasing HP loads ([Bell et al.,
2005](#ref-bell2005interspecific)). Therefore, mitigating HP deposition
likely requires the focal plant to leverage context-altering traits,
such as extreme localised floral density or fine-scale temporal
stratification ([Štenc et al., 2025](#ref-stenc2025pollen)), to
effectively override the neighbourhood effect and maintain vector
constancy. Furthermore, as demonstrated by Venjakob et al.
([2016](#ref-venjakob2016plant)), higher plant diversity within the
community can actively promote spatio-temporal niche complementarity
among pollinators. By partitioning their foraging across different times
of day and vegetation heights, distinct pollinator groups can reduce
their interspecific overlap, functioning as an additional
community-level buffer against heterospecific pollen transfer.

Nevertheless, our study possesses limitations that must be addressed in
future research. First, while we found no significant differences among
morphological groups of pollinators in their single-visit pollen
deposition, this lack of distinction may be partially obscured by the
extreme stochasticity of individual visits, potentially requiring more
exhaustive sampling to detect subtle taxonomic variations in pollinator
effectiveness ([King et al., 2013](#ref-king2013)). Second, our
single-visit deposition (SVD) methodology provides a robust snapshot of
mechanical transfer, but it does not explicitly track the previous
foraging history or complex pollen carryover dynamics of individual
pollinators prior to capture ([Thomson and Plowright,
1980](#ref-thomson1980)). Consequently, while our data demonstrate that
multiple SVD events mathematically aggregate into stable conspecific
pollen (CP) loads, we currently lack the genetic parentage data, as well
as the data on stigma receptivity and pollen tube germination required
to confirm whether this high visitation redundancy translates into a
highly diverse pollen donor pool and subsequent gametophytic competition
along the pathway to paternity ([Minnaar et al.,
2019](#ref-Minnaar2019); [Stavert et al.,
2020](#ref-stavert2020pollen)).

The fact that the pollen deposited on stigmas is the result of multiple
SVD events suggests that the composition of pollen competing for ovule
fertilisation is potentially formed by pollen from several distinct
donors. This has crucial implications for pollen-pollen competition,
male reproductive success, and ultimately, population genetic
variability. A vital remaining question is whether the pollen delivered
during the first visits has a decisive competitive advantage over
later-delivered pollen ([Lankinen and Madjidian,
2011](#ref-lankinen2011enhancing)), or if this advantage is limited by
the timing of stigma receptivity acting as a synchronised starting gate
([Herrero, 2003](#ref-herrero2003male)) . Beyond this micro-scale
pollen-pollen competition, the macro-scale genetic implications of these
stochastic visits remain entirely unknown. Because vector foraging
behaviour and heterospecific carryover fluctuate wildly with local
floral density ([Arceo-Gómez and Ashman, 2011](#ref-ArceoGomez2011)),
the hidden donor-acceptor “mating network” may undergo radical
year-to-year rewiring ([Fortuna and Bascompte, 2006](#ref-Fortuna2006)).
Determining whether these dynamic micro-competitive mechanisms and
macro-level network shifts are unique responses to the high-density
anomaly of *S. pratensis*, or whether they represent a broadly
generalisable feature of high-redundancy generalist systems, stands as a
vital frontier for future ecological and evolutionary research.

#### Conclusions

Ultimately, our multi-scale analysis demonstrates that stable pollen
transfer in generalised networks is driven by distinct, scale-dependent
mechanisms. While individual generalist vectors exhibit extreme
depositional stochasticity, plants achieve reliable conspecific pollen
receipt through the statistical averaging of redundant visits. However,
this visitation redundancy alone is functionally insufficient to prevent
reproductive interference from the co-flowering community, and
variations in community composition may influence HP transfer. Instead,
the mitigation of heterospecific pollen accumulation relies on the local
spatial structure of the focal population and possibly pollinator
temporal specialisation ([Brosi, 2016](#ref-Brosi2016); [Štenc et al.,
2025](#ref-stenc2025pollen)).

## Data Availability

The datasets used in this study are available in the supplementary
material and have been exported for archiving.

## Acknowledgements

This research was supported by the Czech Science Foundation (grant
No. 23-06433S). We are also grateful to the members of the PEE and PEG
groups for suggestions during writing the manuscript, namely Tomáš
Herben and Martin Weiser. Lastly, we acknowledge the support of the
Municipality of Chlístovice in providing access to the study sites and
field laboratory.

## Supplementary Material

## References

<div id="refs" class="references csl-bib-body hanging-indent">

<div id="ref-aguirre2024floral" class="csl-entry">

Aguirre, L. A., and R. R. Junker. 2024. Floral and pollinator functional
diversity mediate network structure along an elevational gradient.
*Alpine Botany* 134: 193–206.

</div>

<div id="ref-arceo2016patterns" class="csl-entry">

Arceo-Gómez, G., C. Alonso, L. Abdala-Roberts, and V. Parra-Tabla. 2016.
Patterns and sources of variation in pollen deposition and pollen tube
formation in flowers of the endemic monoecious shrub cnidoscolus souzae
(euphorbiaceae). *Plant Biology* 18: 594–600.

</div>

<div id="ref-ArceoGomez2011" class="csl-entry">

Arceo-Gómez, G., and T. L. Ashman. 2011. [Heterospecific pollen
deposition: Does diversity alter the
consequences?](https://doi.org/10.1111/J.1469-8137.2011.03831.X) *New
Phytologist* 192: 738–746.

</div>

<div id="ref-bartos2020self" class="csl-entry">

Bartoš, M., Š. Janeček, P. Janečková, E. Padyšáková, R. Tropek, L.
Götzenberger, Y. Klomberg, and J. Jersáková. 2020. Self-compatibility
and autonomous selfing of plants in meadow communities. *Plant Biology*
22: 120–128.

</div>

<div id="ref-beattie1971technique" class="csl-entry">

Beattie, A. 1971. A technique for the study of insect-borne pollen. *The
Pan-Pacific Entomologist* 47: 82.

</div>

<div id="ref-bell2005interspecific" class="csl-entry">

Bell, J. M., J. D. Karron, and R. J. Mitchell. 2005. Interspecific
competition for pollination lowers seed production and outcrossing in
mimulus ringens. *Ecology* 86: 762–771.

</div>

<div id="ref-Brosi2016" class="csl-entry">

Brosi, B. J. 2016. [Pollinator specialization: From the individual to
the community](https://doi.org/10.1111/nph.13951). *New Phytologist*:
1190–1194.

</div>

<div id="ref-cullen2021diversity" class="csl-entry">

Cullen, N., J. Xia, N. Wei, R. Kaczorowski, G. Arceo-Gómez, E. O’Neill,
R. Hayes, and T.-L. Ashman. 2021. Diversity and composition of pollen
loads carried by pollinators are primarily driven by insect traits, not
floral community characteristics. *Oecologia* 196: 131–143.

</div>

<div id="ref-fang2019multi" class="csl-entry">

Fang, Q., J. Gao, W. S. Armbruster, and S.-Q. Huang. 2019. Multi-year
stigmatic pollen-load sampling reveals temporal stability in
interspecific pollination of flowers in a subalpine meadow. *Oikos* 128:
1739–1747.

</div>

<div id="ref-Fang2022" class="csl-entry">

Fang, Q., S. Guo, T. Zhang, and X. Tang. 2022. [Relative stable
interannual variation in plant‒plant pollen transfer rather than the
plant‒pollinator network of a subalpine
meadow](https://doi.org/10.1093/jpe/rtac094). *Journal of Plant
Ecology*.

</div>

<div id="ref-flanagan2022pollinator" class="csl-entry">

Flanagan, R. J., R. J. Mitchell, and J. D. Karron. 2010. Increased
relative abundance of an invasive competitor for pollination, lythrum
salicaria, reduces seed number in mimulus ringens. *Oecologia* 164:
445–454.

</div>

<div id="ref-Fortuna2006" class="csl-entry">

Fortuna, M. A., and J. Bascompte. 2006. [Habitat loss and the structure
of plant–animal mutualistic
networks](https://doi.org/10.1111/J.1461-0248.2005.00868.X). *Ecology
Letters* 9: 281–286.

</div>

<div id="ref-freudenfeld2025interannual" class="csl-entry">

Freudenfeld, M., J. Štenc, J. Hadrava, M. Mikát, E. Matoušková, K.
Daňková, T. Jor, et al. 2025. Interannual differences in pollinator
contributions to pollen transfer are mainly driven by changes in
pollinator abundance. *AoB Plants* 17: plaf009.

</div>

<div id="ref-herrera1987" class="csl-entry">

Herrera, C. M. 1987. [Components of pollinator "quality": Comparative
analysis of a diverse insect
assemblage](https://doi.org/10.2307/3565403). *Oikos* 50: 79.

</div>

<div id="ref-herrero2003male" class="csl-entry">

Herrero, M. 2003. Male and female synchrony and the regulation of mating
in flowering plants. *Philosophical Transactions of the Royal Society of
London. Series B: Biological Sciences* 358: 1019–1024.

</div>

<div id="ref-hildesheim2019quantitative" class="csl-entry">

Hildesheim, L. S., Ø. H. Opedal, W. S. Armbruster, and C. Pélabon. 2019.
Quantitative and qualitative consequences of reduced pollen loads in a
mixed-mating plant. *Ecology and Evolution* 9: 14253–14260.

</div>

<div id="ref-holmquist2012influence" class="csl-entry">

Holmquist, K. G., R. J. Mitchell, and J. D. Karron. 2012. Influence of
pollinator grooming on pollen-mediated gene dispersal in mimulus ringens
(phrymaceae). *Plant Species Biology* 27: 77–85.

</div>

<div id="ref-horn1966measurement" class="csl-entry">

Horn, H. S. 1966. Measurement of" overlap" in comparative ecological
studies. *The American Naturalist* 100: 419–424.

</div>

<div id="ref-janovsky2013conspecific" class="csl-entry">

Janovský, Z., M. Mikát, J. Hadrava, E. Horčičková, K. Kmecová, D.
Požárová, J. Smyčka, and T. Herben. 2013a. Conspecific and
heterospecific plant densities at small-scale can drive plant-pollinator
interactions. *PLoS One* 8: e77361.

</div>

<div id="ref-Janovsky2013" class="csl-entry">

Janovský, Z., M. Mikát, J. Hadrava, E. Horčičková, K. Kmecová, D.
Požárová, J. Smyčka, and T. Herben. 2013b. [Conspecific and
heterospecific plant densities at small-scale can drive plant-pollinator
interactions](https://doi.org/10.1371/journal.pone.0077361). *PLoS ONE*
8: 77361.

</div>

<div id="ref-king2013" class="csl-entry">

King, C., G. Ballantyne, and P. G. Willmer. 2013. [Why flower visitation
is a poor proxy for pollination: Measuring single-visit pollen
deposition, with implications for pollination networks and
conservation](https://doi.org/10.1111/2041-210X.12074). *Methods in
Ecology and Evolution* 4: 811818.

</div>

<div id="ref-lankinen2011enhancing" class="csl-entry">

Lankinen, Å., and J. A. Madjidian. 2011. Enhancing pollen competition by
delaying stigma receptivity: Pollen deposition schedules affect siring
ability, paternal diversity, and seed production in collinsia
heterophylla (plantaginaceae). *American Journal of Botany* 98:
1191–1200.

</div>

<div id="ref-Lazaro2009" class="csl-entry">

Lázaro, A., R. Lundgren, and Ø. Totland. 2009. [Co-flowering neighbors
influence the diversity and identity of pollinator groups visiting plant
species](https://doi.org/10.1111/j.1600-0706.2008.17168.x). *Oikos* 118:
691–702.

</div>

<div id="ref-madjidian2020direct" class="csl-entry">

Madjidian, J. A., H. G. Smith, S. Andersson, and Å. Lankinen. 2020.
Direct and indirect selection on mate choice during pollen competition:
Effects of male and female sexual traits on offspring performance
following two-donor crosses. *Journal of evolutionary biology* 33:
1452–1467.

</div>

<div id="ref-Minnaar2019" class="csl-entry">

Minnaar, C., B. Anderson, M. L. D. Jager, and J. D. Karron. 2019.
[Plant-pollinator interactions along the pathway to
paternity](https://doi.org/10.1093/aob/mcy167). *Annals of Botany* 123:
225–245.

</div>

<div id="ref-morales2013heterospecific" class="csl-entry">

Morales, C. L., and A. Traveset. 2013. Heterospecific pollen deposition:
Does diversity matter? *Functional Ecology* 27: 130–137.

</div>

<div id="ref-morales2008interspecific" class="csl-entry">

Morales, C. L., and A. Traveset. 2008. Interspecific pollen transfer:
Magnitude, prevalence and consequences for plant fitness. *Critical
Reviews in Plant Sciences* 27: 221–238.

</div>

<div id="ref-neeman2001" class="csl-entry">

Ne’eman, G., and P. G. Kevan. 2001. [The effect of shape parameters on
maximal detection distance of model targets by honeybee
workers](https://doi.org/10.1007/s003590100237). *Journal of Comparative
Physiology - A Sensory, Neural, and Behavioral Physiology* 187: 653660.

</div>

<div id="ref-Rcore" class="csl-entry">

R Core Team. 2025. [R: A language and environment for statistical
computing](https://www.R-project.org/). R Foundation for Statistical
Computing, Vienna, Austria.

</div>

<div id="ref-richards2009variation" class="csl-entry">

Richards, S. A., N. M. Williams, and L. D. Harder. 2009. Variation in
pollination: Causes and consequences for plant reproduction. *The
American Naturalist* 174: 382–398.

</div>

<div id="ref-Schwarz2021" class="csl-entry">

Schwarz, B., C. F. Dormann, D. P. Vázquez, and J. Fründ. 2021.
[Within-day dynamics of plant–pollinator networks are dominated by early
flower closure: An experimental test of network
plasticity](https://doi.org/10.1007/s00442-021-04952-5). *Oecologia*
196: 781–794.

</div>

<div id="ref-stavert2020pollen" class="csl-entry">

Stavert, J. R., C. Bailey, L. Kirkland, and R. Rader. 2020. Pollen tube
growth from multiple pollinator visits more accurately quantifies
pollinator performance and plant reproduction. *Scientific Reports* 10:
16958.

</div>

<div id="ref-stenc2023pollinator" class="csl-entry">

Štenc, J., L. Janošík, E. Matoušková, J. Hadrava, M. Mikát, and Z.
Janovský. 2023. Pollinator visitation closely tracks diurnal patterns in
pollen release. *American Journal of Botany* 110: e16179.

</div>

<div id="ref-stenc2025pollen" class="csl-entry">

Štenc, J., L. Janošı́k, M. Freudenfeld, E. Matoušková, J. Hadrava, M.
Mikát, K. Daňková, et al. 2025. Pollen presentation mitigates
competition for pollinators due to diurnal stratification of pollen
transfer. *Perspectives in Plant Ecology, Evolution and Systematics* 67:
125868.

</div>

<div id="ref-Stone1998" class="csl-entry">

Stone, G. N., P. Willmer, and J. A. Rowe. 1998. [Partitioning of
pollinators during flowering in an african acacia
community](https://doi.org/10.1890/0012-9658(1998)079[2808:popdfi]2.0.co;2).
*Ecology* 79: 2808–2827.

</div>

<div id="ref-thomson1980" class="csl-entry">

Thomson, J. D., and R. C. Plowright. 1980. [Pollen carryover, nectar
rewards, and pollinator behavior with special reference to diervilla
loniceraPollen carryover, nectar rewards, and pollinator behavior with
special reference to diervilla
lonicera](https://doi.org/10.1007/BF00346968). *Oecologia* 46: 68–74.

</div>

<div id="ref-valdovinos2025effect" class="csl-entry">

Valdovinos, F. S. 2025. Effect of network structure and adaptive
foraging on pollination services of species-rich plant-pollinator
communities. *Integrative and Comparative Biology* 65: 981–990.

</div>

<div id="ref-valverde2019" class="csl-entry">

Valverde, J., F. Perfectti, and J. M. Gómez. 2019. [Pollination
effectiveness in a generalist plant: Adding the genetic
component](https://doi.org/10.1111/nph.15743). *New Phytologist* 223:
354365.

</div>

<div id="ref-vazquez2005degree" class="csl-entry">

Vázquez, D. P. 2005. Degree distribution in plant–animal mutualistic
networks: Forbidden links or random interactions? *Oikos* 108: 421–426.

</div>

<div id="ref-venjakob2016plant" class="csl-entry">

Venjakob, C., A.-M. Klein, A. Ebeling, T. Tscharntke, and C. Scherber.
2016. Plant diversity increases spatio-temporal niche complementarity in
plant-pollinator interactions. *Ecology and evolution* 6: 2249–2261.

</div>

<div id="ref-ye2020" class="csl-entry">

Ye, Z. M., X. F. Jin, Q. F. Wang, and C. F. Yang. 2020. [Co-flowering
neighbor alters pollinator composition and influences reproductive
success in a plant pollinated by multiple
insects](https://doi.org/10.1007/S11258-020-01000-9/TABLES/2). *Plant
Ecology* 221: 219–228.

</div>

</div>
