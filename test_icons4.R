library(ggplot2)
library(patchwork)
library(ggtext)

# dummy data A
cv_data <- expand.grid(Compartment = c("Body", "SVD", "TPD"), Pollen_Type = c("CP", "HP"))
cv_data$CV <- runif(6, 50, 350)
cv_data$icon_html <- sprintf("<img src='%s' width='%d' />", "images/TPD.png", 20)
max_cv <- max(cv_data$CV)
y_limit_max <- max_cv * 1.45

p_cv <- ggplot(cv_data, aes(x = Compartment, y = CV, fill = Pollen_Type)) +
    geom_bar(stat = "identity", position = position_dodge(width = 0.9), color = "black", width = 0.8) +
    ggtext::geom_richtext(aes(y = max_cv * 1.25, label = icon_html, group = Pollen_Type), 
                          position = position_dodge(width = 0.9),
                          vjust = 0.5, fill = NA, label.color = NA) +
    scale_y_continuous(limits = c(0, y_limit_max)) +
    theme_classic() + theme(legend.position = "none")

# dummy data B
cv_by_year <- expand.grid(Year = factor(c("2022", "2023", "2024")), Pollen_Type = c("CP", "HP"))
cv_by_year$CV <- runif(6, 50, 125)
max_cv_year <- max(cv_by_year$CV)

icon_df_B <- data.frame(
    x = c(2.8, 3.3),
    y = c(max_cv_year * 1.25, max_cv_year * 1.25),
    icon_html = c(
        sprintf("<img src='%s' width='%d' />", "images/TPD.png", 20),
        sprintf("<img src='%s' width='%d' />", "images/TPD_HP.png", 20)
    )
)

p_cv_year <- ggplot(cv_by_year, aes(x = Year, y = CV, fill = Pollen_Type)) +
    geom_bar(stat = "identity", position = position_dodge(width = 0.9), color = "black", width = 0.8) +
    ggtext::geom_richtext(data = icon_df_B, aes(x = x, y = y, label = icon_html),
                          fill = NA, label.color = NA, inherit.aes = FALSE, vjust = 0.5) +
    scale_y_continuous(limits = c(0, max_cv_year * 1.45)) +
    theme_classic() + theme(legend.position = "none")

ggsave("test_icons4.png", p_cv + p_cv_year, width=10, height=5, bg="white")
