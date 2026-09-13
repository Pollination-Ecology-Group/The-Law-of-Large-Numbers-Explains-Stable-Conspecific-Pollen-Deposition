library(ggplot2)
library(cowplot)
library(patchwork)

# dummy p_model
p_model <- ggplot(mtcars, aes(x=wt, y=mpg, color=factor(cyl))) + 
    geom_point() + geom_smooth(method="lm") +
    labs(x = "Conspecific Pollen (mean per plant)", y = "Heterospecific Pollen (mean per plant)") +
    theme_classic() + theme(legend.position="right")

p_model_icon <- ggdraw(p_model) +
    draw_image("images/TPD_HP.png", x = 0.02, y = 0.98, hjust = 0, vjust = 1, width = 0.15, height = 0.15) +
    draw_image("images/TPD.png", x = 0.98, y = 0.12, hjust = 1, vjust = 0, width = 0.15, height = 0.15)

ggsave("test_model_icons.png", p_model_icon, width=8, height=6, bg="white")
