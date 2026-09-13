library(ggplot2)
library(cowplot)
library(patchwork)

pred_grid <- data.frame(mean_CP = seq(0, 75, length.out=10), lwr_HP = seq(0, 100, length.out=10), upr_HP = seq(20, 160, length.out=10), pred_HP = seq(10, 130, length.out=10), Year=factor(2022))
aggregated_data <- data.frame(mean_CP = runif(50, 0, 75), mean_HP = runif(50, 0, 160), Year=factor(2022))

p_model <- ggplot() +
    geom_ribbon(data = pred_grid, aes(x = mean_CP, ymin = lwr_HP, ymax = upr_HP, fill = Year), alpha = 0.2) +
    geom_point(data = aggregated_data, aes(x = mean_CP, y = mean_HP, color = Year), alpha = 0.6, size = 2) +
    geom_line(data = pred_grid, aes(x = mean_CP, y = pred_HP, color = Year), linewidth = 1.2) +
    geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "gray50", linewidth = 0.8) +
    labs(
        x = "Conspecific Pollen (mean per plant)",
        y = "Heterospecific Pollen (mean per plant)"
    ) +
    theme_classic() +
    theme(
        legend.position = "right"
    )

p_model_icon <- ggdraw(p_model) +
    draw_image("images/TPD_HP.png", x = 0.10, y = 0.90, hjust = 0, vjust = 1, width = 0.12, height = 0.12) +
    draw_image("images/TPD.png", x = 0.82, y = 0.22, hjust = 1, vjust = 0, width = 0.12, height = 0.12)

ggsave("test_model_icons2.png", p_model_icon, width=10, height=5, bg="white")
