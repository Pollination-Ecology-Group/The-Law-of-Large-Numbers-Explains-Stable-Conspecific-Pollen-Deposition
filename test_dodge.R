library(ggplot2)
library(ggtext)
df <- data.frame(
  Compartment = c("Body", "Body", "SVD", "SVD"),
  Pollen_Type = c("CP", "HP", "CP", "HP"),
  CV = c(100, 200, 150, 250),
  icon_html = c("A", "B", "C", "D")
)

p <- ggplot(df, aes(x = Compartment, y = CV, fill = Pollen_Type)) +
  geom_bar(stat = "identity", position = position_dodge(width = 0.9)) +
  geom_richtext(aes(y = CV + 10, label = icon_html, group = Pollen_Type), 
                position = position_dodge(width = 0.9),
                fill = NA)
ggsave("test_dodge.png", p)
