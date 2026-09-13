library(ggplot2)
library(patchwork)
library(cowplot)

p1 <- ggplot(mtcars, aes(factor(cyl), mpg)) + geom_boxplot() + ggtitle("A. Body CP")
p2 <- ggplot(mtcars, aes(factor(cyl), hp)) + geom_boxplot() + ggtitle("B. Body HP")
p3 <- ggplot(mtcars, aes(factor(cyl), disp)) + geom_boxplot() + ggtitle("C. SVD CP")
p4 <- ggplot(mtcars, aes(factor(cyl), wt)) + geom_boxplot() + ggtitle("D. SVD HP")

p1 <- ggdraw(p1) + draw_image("images/Pollen_load_CP.png", x = 1, y = 1, hjust = 1, vjust = 1, width = 0.2, height = 0.2)
p2 <- ggdraw(p2) + draw_image("images/Pollen_load_HP.png", x = 1, y = 1, hjust = 1, vjust = 1, width = 0.2, height = 0.2)
p3 <- ggdraw(p3) + draw_image("images/SVD.png", x = 1, y = 1, hjust = 1, vjust = 1, width = 0.2, height = 0.2)
p4 <- ggdraw(p4) + draw_image("images/SVD_HP.png", x = 1, y = 1, hjust = 1, vjust = 1, width = 0.2, height = 0.2)

combined <- (p1 | p2) / (p3 | p4)

ggsave("test_inset.png", combined, width=10, height=8)
