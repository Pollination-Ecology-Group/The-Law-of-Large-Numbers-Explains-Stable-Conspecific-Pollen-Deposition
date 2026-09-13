# ==============================================================================
# Script: generate_graphical_abstract_v3.R
# Purpose: Generate the graphical abstract (Version 3) for the manuscript
# ==============================================================================

# Load required packages
library(ggplot2)
library(cowplot)
library(magick)
library(ggtext)

# Set base directory for images
img_dir <- "images/"
out_dir <- "output/figures/"

# --- 1. Load Images ---
img_pollinator <- image_read(paste0(img_dir, "Pollinator.png"))
img_stigma     <- image_read(paste0(img_dir, "Stigma.png"))
img_svd_cp     <- image_read(paste0(img_dir, "SVD.png"))
img_svd_hp     <- image_read(paste0(img_dir, "SVD_HP.png"))
img_tpd_cp     <- image_read(paste0(img_dir, "TPD.png"))
img_tpd_hp     <- image_read(paste0(img_dir, "TPD_HP.png"))
img_plant      <- image_read(paste0(img_dir, "plant.png"))

# --- 2. Build the Panels ---

# A) Left Panel: The Swarm (Visitation Redundancy)
p_left <- ggdraw() +
  # Swarm of pollinators
  draw_image(img_pollinator, x = 0.1, y = 0.55, width = 0.2, height = 0.2) +
  draw_image(img_pollinator, x = 0.3, y = 0.65, width = 0.2, height = 0.2) +
  draw_image(img_pollinator, x = 0.2, y = 0.40, width = 0.2, height = 0.2) +
  draw_image(img_pollinator, x = 0.4, y = 0.50, width = 0.2, height = 0.2) +
  draw_image(img_pollinator, x = 0.5, y = 0.60, width = 0.2, height = 0.2) +
  draw_image(img_pollinator, x = 0.6, y = 0.45, width = 0.2, height = 0.2) +
  
  # Text
  draw_label("High Visitation Redundancy", x = 0.5, y = 0.90, fontface = "bold", size = 18) +
  draw_label("Accumulation of Visits", x = 0.5, y = 0.85, size = 14, color = "gray30") +
  
  # Arrow pointing right
  draw_line(x = c(0.75, 0.95), y = c(0.55, 0.55), arrow = arrow(length = unit(0.5, "cm"), type = "closed"), color = "#4675ED", linewidth = 3)

# B) Center Panel: SVD and Summation
p_center <- ggdraw() +
  draw_label("Single Visit Deposition (SVD)", x = 0.5, y = 0.90, fontface = "bold", size = 18) +
  draw_label("Highly Variable & Inefficient", x = 0.5, y = 0.85, size = 14, color = "gray30") +
  
  # SVD CP
  draw_image(img_svd_cp, x = 0.1, y = 0.45, width = 0.35, height = 0.3) +
  draw_label("Conspecific (CP)", x = 0.27, y = 0.40, size = 12, hjust = 0.5, fontface = "bold") +
  
  # SVD HP
  draw_image(img_svd_hp, x = 0.55, y = 0.45, width = 0.35, height = 0.3) +
  draw_label("Heterospecific (HP)", x = 0.72, y = 0.40, size = 12, hjust = 0.5, fontface = "bold") +
  
  # Summation symbol and text
  draw_label("Σ", x = 0.5, y = 0.25, fontface = "bold", size = 48, color = "#39568C") +
  draw_label("Law of Large Numbers", x = 0.5, y = 0.12, fontface = "italic", size = 12, color = "gray20") +
  
  # Arrow pointing right
  draw_line(x = c(0.7, 0.95), y = c(0.25, 0.25), arrow = arrow(length = unit(0.5, "cm"), type = "closed"), color = "#4675ED", linewidth = 3)


# C) Right Panel: TPD and Floral Density
p_right <- ggdraw() +
  draw_label("Terminal Pollen Deposition (TPD)", x = 0.5, y = 0.90, fontface = "bold", size = 18) +
  draw_label("Macro-scale Stability", x = 0.5, y = 0.85, size = 14, color = "gray30") +
  
  # TPD CP
  draw_image(img_tpd_cp, x = 0.1, y = 0.45, width = 0.35, height = 0.3) +
  draw_label("Stable CP Deposition\n(Reproductive Assurance)", x = 0.27, y = 0.40, size = 12, hjust = 0.5, color = "#1E9C89", fontface = "bold") +
  
  # TPD HP
  draw_image(img_tpd_hp, x = 0.55, y = 0.45, width = 0.35, height = 0.3) +
  draw_label("Variable HP Accumulation\n(Context-Dependent)", x = 0.72, y = 0.40, size = 12, hjust = 0.5, color = "#D2204C", fontface = "bold") +
  
  # Floral Density Representation (Cluster of plants)
  draw_image(img_plant, x = 0.50, y = 0.05, width = 0.15, height = 0.15) +
  draw_image(img_plant, x = 0.60, y = 0.05, width = 0.15, height = 0.15) +
  draw_image(img_plant, x = 0.70, y = 0.05, width = 0.15, height = 0.15) +
  draw_label("High Floral Density\nmitigates HP Interference", x = 0.65, y = 0.25, size = 12, hjust = 0.5, color = "gray20", fontface = "bold") +
  
  # Upward arrow showing mitigation effect
  draw_line(x = c(0.65, 0.65), y = c(0.20, 0.32), arrow = arrow(length = unit(0.3, "cm"), type = "closed"), color = "gray40", linewidth = 2)

# --- 3. Assemble Final Graphical Abstract ---
final_plot <- plot_grid(
  p_left, p_center, p_right, 
  ncol = 3, 
  rel_widths = c(1, 1.2, 1.2),
  align = "h"
)

title_plot <- ggdraw() + 
  draw_label("The law of large numbers explains stable conspecific pollen deposition", 
             fontface = "bold", size = 26, color = "black")

graphical_abstract <- plot_grid(
  title_plot, final_plot,
  ncol = 1,
  rel_heights = c(0.1, 1)
)

# --- 4. Export ---
out_png <- paste0(out_dir, "graphical_abstract_v3.png")
out_svg <- paste0(out_dir, "graphical_abstract_v3.svg")

ggsave(out_png, plot = graphical_abstract, width = 16, height = 9, dpi = 300, bg = "white")
ggsave(out_svg, plot = graphical_abstract, width = 16, height = 9, bg = "white")

message("Graphical abstract v3 successfully saved to: ", out_png)
