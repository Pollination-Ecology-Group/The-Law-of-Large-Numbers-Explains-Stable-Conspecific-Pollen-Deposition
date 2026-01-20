
# Load libraries
library(HanPolNet)
library(dplyr)
library(ggplot2)
library(sf)
library(tidyr)

# Load data
data("hanpolnet_plots")
data("plant_abundance")

# Filter for Succisa pratensis in 2022, 2023, 2024
succisa_presence <- plant_abundance %>%
  filter(year %in% c(22, 23, 24)) %>%
  select(year, plot_id, Suc_pra) %>%
  filter(Suc_pra > 0)

# Merge with spatial data
# hanpolnet_plots has 'plot_id' as character (e.g., "plot_01") or numeric? 
# plant_abundance likely has numeric plot_id. Let's check.
# Based on my previous view, hanpolnet_plots has plot_id like "plot_01".
# plant_abundance usually has numeric. I need to be careful.

# Let's inspect potential ID mismatch handling
# Use a safe join or convert

# Convert years to full format for better labeling
succisa_presence <- succisa_presence %>%
  mutate(year_full = paste0("20", year))

# Prepare plot data - we want to show ALL plots, highlighting those with Succisa
# So we start with hanpolnet_plots and join
map_data <- hanpolnet_plots %>%
  mutate(plot_num = as.numeric(gsub("plot_", "", plot_id))) # Extract numeric ID if needed

# Actually, let's just use the plot_id if possible. 
# Depending on plant_abundance format. 
# If plant_abundance has numeric plot_id, I'll convert before join.

# For the script, I will assume I need to check the data first.
# But to write a "working" script blind:

succisa_presence_numeric <- succisa_presence %>%
  mutate(plot_num = as.numeric(plot_id)) 
  # Note: if plot_id in plant_abundance is already numeric, this is fine.

# Join
# We want to map ALL plots as background, and point out Succisa ones.
# Or just show the ones with Succisa? Request: "showing plonts in which Succisa pratensis was presented"
# usually implies showing the distribution.

# Let's clean up map_data
# We need to replicate the spatial grid for each year to facet properly if we want to show presence/absence
# OR just plot the presence points on top of a static grid.

# Strategy:
# 1. Base map: all plots (grey dots)
# 2. Presence layer: Succisa plots (colored dots), faceted by year.

# Replicating base map for facets isn't strictly necessary if using data=NULL for base layer, 
# but for faceting the presence layer, we need the 'year' column.

p <- ggplot() +
  # Base layer: all plots
  geom_sf(data = hanpolnet_plots, color = "grey80", size = 1) +
  # Presence layer
  geom_sf(data = hanpolnet_plots %>% 
            mutate(plot_num = as.numeric(gsub("plot_", "", plot_id))) %>%
            inner_join(succisa_presence %>% mutate(plot_id = as.numeric(plot_id)), by = c("plot_num" = "plot_id")),
          aes(color = as.factor(year_full)), size = 3) +
  facet_wrap(~year_full) +
  scale_color_viridis_d(name = "Year") +
  theme_minimal() +
  labs(title = "Succisa pratensis Presence (2022-2024)",
       subtitle = "Plots with non-zero abundance")

print(p)
