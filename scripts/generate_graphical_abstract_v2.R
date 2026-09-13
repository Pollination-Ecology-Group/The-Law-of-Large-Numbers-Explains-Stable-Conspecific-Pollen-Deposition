# ==============================================================================
# Script: generate_graphical_abstract.R
# Purpose: Generate the graphical abstract for the manuscript
# "The law of large numbers explains stable conspecific pollen deposition"
# ==============================================================================

# Load required packages
if (!requireNamespace("ggplot2", quietly = TRUE)) install.packages("ggplot2")
if (!requireNamespace("cowplot", quietly = TRUE)) install.packages("cowplot")
if (!requireNamespace("magick", quietly = TRUE)) install.packages("magick")
if (!requireNamespace("ggtext", quietly = TRUE)) install.packages("ggtext")

library(ggplot2)
library(cowplot)
library(magick)
library(ggtext)

# Set base directory for images
img_dir <- "images/"

# Ensure output directory exists
out_dir <- "output/figures/"
if (!dir.exists(out_dir)) {
  dir.create(out_dir, recursive = TRUE)
}

# --- 1. Load Images ---
img_pollinator <- image_read(paste0(img_dir, "Pollinator.png"))
img_stigma     <- image_read(paste0(img_dir, "Stigma.png"))
img_svd_cp     <- image_read(paste0(img_dir, "SVD.png"))
img_svd_hp     <- image_read(paste0(img_dir, "SVD_HP.png"))
img_tpd_cp     <- image_read(paste0(img_dir, "TPD.png"))
img_tpd_hp     <- image_read(paste0(img_dir, "TPD_HP.png"))
img_plant      <- image_read(paste0(img_dir, "plant.png"))
img_pollen_cp  <- image_read(paste0(img_dir, "Pollen_load_CP.png"))
img_pollen_hp  <- image_read(paste0(img_dir, "Pollen_load_HP.png"))

# Create theme settings for text
title_theme <- element_markdown(face = "bold", size = 20, hjust = 0.5, family = "sans")
subtitle_theme <- element_markdown(size = 14, hjust = 0.5, family = "sans", color = "gray20")
box_theme <- element_rect(fill = "#f7f7f7", color = "gray80", linewidth = 2)


# --- 2. Build the Panels ---

# Helper to create a panel with a background
panel_bg <- ggplot() + 
  theme_void() + 
  theme(panel.background = element_rect(fill = "white", color = "gray80", linewidth = 1))

# A) Left Panel: Micro-scale Chaos (Single Visits)
p_left <- ggdraw(panel_bg) +
  # Title
  draw_label("Micro-Scale Stochasticity", x = 0.5, y = 0.95, fontface = "bold", size = 22) +
  draw_label("Single Visit Deposition (SVD)", x = 0.5, y = 0.90, size = 16, color = "gray30") +
  
  # Images
  draw_image(img_pollinator, x = 0.2, y = 0.55, width = 0.3, height = 0.3) +
  draw_label("Pollinator", x = 0.35, y = 0.53, size = 12, hjust = 0.5, fontface = "bold") +
  draw_image(img_stigma, x = 0.55, y = 0.55, width = 0.2, height = 0.3) +
  draw_label("Stigma", x = 0.65, y = 0.53, size = 12, hjust = 0.5, fontface = "bold") +
  
  # Arrows splitting to CP and HP
  draw_line(x = c(0.5, 0.3), y = c(0.53, 0.40), arrow = arrow(length = unit(0.3, "cm"), type = "closed"), color = "gray50", linewidth = 2) +
  draw_line(x = c(0.5, 0.7), y = c(0.53, 0.40), arrow = arrow(length = unit(0.3, "cm"), type = "closed"), color = "gray50", linewidth = 2) +
  
  # SVD CP
  draw_image(img_svd_cp, x = 0.1, y = 0.08, width = 0.35, height = 0.3) +
  draw_label("Conspecific (CP)\nHighly Inefficient & Variable", x = 0.27, y = 0.03, size = 12, hjust = 0.5, fontface = "bold") +
  
  # SVD HP
  draw_image(img_svd_hp, x = 0.55, y = 0.08, width = 0.35, height = 0.3) +
  draw_label("Heterospecific (HP)\nUnpredictable Carryover", x = 0.72, y = 0.03, size = 12, hjust = 0.5, fontface = "bold")
  

# B) Center Panel: The Variance Filter (Law of Large Numbers)
p_center <- ggdraw() +
  # Graphical accumulation (multiple pollen loads) jittered
  draw_image(img_pollen_cp, x = 0.10, y = 0.54, width = 0.25, height = 0.25) +
  draw_image(img_pollen_hp, x = 0.40, y = 0.52, width = 0.25, height = 0.25) +
  draw_image(img_pollen_cp, x = 0.70, y = 0.55, width = 0.25, height = 0.25) +
  draw_image(img_pollen_cp, x = 0.10, y = 0.16, width = 0.25, height = 0.25) +
  draw_image(img_pollen_hp, x = 0.40, y = 0.18, width = 0.25, height = 0.25) +
  draw_image(img_pollen_cp, x = 0.70, y = 0.15, width = 0.25, height = 0.25) +
  
  # The central arrow
  draw_line(x = c(0.1, 0.9), y = c(0.48, 0.48), arrow = arrow(length = unit(0.8, "cm"), type = "closed"), color = "#4675ED", linewidth = 4) +
  
  # Summation symbol slightly above the center of the arrow
  draw_label("Σ", x = 0.5, y = 0.54, fontface = "bold", size = 48, color = "#39568C") +
  
  # Text moved up to avoid overlap
  draw_label("Accumulation Over Time", x = 0.5, y = 0.90, fontface = "bold", size = 18, color = "#39568C") +
  draw_label("High Visitation Redundancy", x = 0.5, y = 0.85, size = 14, fontface = "italic", color = "gray20") +
  
  # Text moved down to avoid overlap
  draw_label("Law of Large Numbers\nfilters micro-scale variance", x = 0.5, y = 0.10, size = 14, color = "gray30", lineheight = 1.1)


# C) Right Panel: Macro-scale Stability (Terminal Deposition)
p_right <- ggdraw(panel_bg) +
  # Title
  draw_label("Macro-Scale Stability", x = 0.5, y = 0.95, fontface = "bold", size = 22) +
  draw_label("Terminal Pollen Deposition (TPD)", x = 0.5, y = 0.90, size = 16, color = "gray30") +
  
  # TPD CP
  draw_image(img_tpd_cp, x = 0.1, y = 0.5, width = 0.35, height = 0.3) +
  draw_label("Stable CP Deposition\n(Reproductive Assurance)", x = 0.27, y = 0.45, size = 12, hjust = 0.5, color = "#1E9C89", fontface = "bold") +
  
  # TPD HP
  draw_image(img_tpd_hp, x = 0.55, y = 0.5, width = 0.35, height = 0.3) +
  draw_label("Variable HP Accumulation\n(Context-Dependent)", x = 0.72, y = 0.45, size = 12, hjust = 0.5, color = "#D2204C", fontface = "bold") +
  
  # Density mitigation icon/text
  draw_image(img_plant, x = 0.30, y = 0.1, width = 0.15, height = 0.15) +
  draw_image(img_plant, x = 0.45, y = 0.1, width = 0.15, height = 0.15) +
  draw_image(img_plant, x = 0.60, y = 0.1, width = 0.15, height = 0.15) +
  draw_label("High Floral Density\nmitigates HP Interference", x = 0.5, y = 0.05, size = 12, hjust = 0.5, color = "gray20", fontface = "bold") +
  # Arrows pointing from plants up to both CP and HP
  draw_line(x = c(0.65, 0.72), y = c(0.25, 0.40), arrow = arrow(length = unit(0.3, "cm"), type = "closed"), color = "gray50", linewidth = 2) +
  draw_line(x = c(0.40, 0.27), y = c(0.25, 0.40), arrow = arrow(length = unit(0.3, "cm"), type = "closed"), color = "gray50", linewidth = 2)


# --- 3. Assemble Final Graphical Abstract ---

final_plot <- plot_grid(
  p_left, p_center, p_right, 
  ncol = 3, 
  rel_widths = c(1.2, 1.0, 1.2),
  align = "h"
)

# Add a unified title overlay
title_plot <- ggdraw() + 
  draw_label("The law of large numbers explains stable conspecific pollen deposition", 
             fontface = "bold", size = 26, color = "black")

graphical_abstract <- plot_grid(
  title_plot, final_plot,
  ncol = 1,
  rel_heights = c(0.1, 1)
) + theme(
  plot.background = element_rect(color = "black", linewidth = 2, fill = "#F4F7F6"),
  plot.margin = margin(10, 10, 10, 10)
)


# --- 4. Export ---
out_png <- paste0(out_dir, "graphical_abstract_v2.png")
out_svg <- paste0(out_dir, "graphical_abstract_v2.svg")

ggsave(out_png, plot = graphical_abstract, width = 16, height = 9, dpi = 300, bg = "#F4F7F6")
ggsave(out_svg, plot = graphical_abstract, width = 16, height = 9, bg = "#F4F7F6")

message("Graphical abstract successfully saved to: ", out_png)
