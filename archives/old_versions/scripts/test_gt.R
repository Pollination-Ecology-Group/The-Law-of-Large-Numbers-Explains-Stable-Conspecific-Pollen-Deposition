library(gt)
library(dplyr)
aov_part <- data.frame(
    Term = c("A", "B"),
    Df = c("1", "2"),
    Stat1 = c("1.0", "2.0"),
    Stat2 = c("1.0", "2.0"),
    Stat3 = c("1.0", "2.0"),
    P_value = c("0.1", "0.2"),
    stringsAsFactors = FALSE
)
aov_part[is.na(aov_part) | aov_part == "NA"] <- ""

aov_part %>%
    gt() %>%
    tab_header(
        title = md("**A) ANOVA Results**")
    ) %>%
    cols_label(
        Term = "Predictor",
        Df = "df",
        Stat1 = "Sum Sq",
        Stat2 = "Mean Sq",
        Stat3 = "F-value",
        P_value = "P-value"
    ) %>%
    tab_style(
        style = cell_text(weight = "bold"),
        locations = cells_column_labels()
    ) %>%
    tab_options(
        column_labels.background.color = "#F0F0F0",
        table.border.top.color = "black",
        table.border.top.width = px(2),
        table.border.bottom.color = "black",
        table.border.bottom.width = px(2),
        data_row.padding = px(6)
    ) %>%
    cols_align(align = "center", columns = c(Df, Stat1, Stat2, Stat3, P_value)) %>%
    cols_align(align = "left", columns = Term) %>%
    opt_align_table_header(align = "left")
