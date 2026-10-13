# Alluvial / Sankey (house style). Highlight one label, rename axes, optional stratum bubbles.
# Flows take the cohort colour; flows that touch the highlighted label stay strong, others fade.
# Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)
library(ggalluvial)

highlight <- "CR"
axis_labels <- c("Cohort", "Subtype", "Response")
show_bubbles <- FALSE
footnote <- "Simulated data for illustration; not biological results"

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$stage1 <- factor(df$stage1, levels = c("Control", "Case", "Treated"))
df$stage2 <- factor(df$stage2, levels = c("LumA", "LumB", "HER2", "Basal"))
df$stage3 <- factor(df$stage3, levels = c("CR", "PR", "SD", "PD", "NE"))
df$on <- df$stage1 == highlight | df$stage2 == highlight | df$stage3 == highlight
hp <- pv_palette("house"); grey <- pv_palette("house_grey")
pal <- stats::setNames(unname(hp[seq_len(nlevels(df$stage1))]), levels(df$stage1))

p <- ggplot(df, aes(y = value, axis1 = stage1, axis2 = stage2, axis3 = stage3)) +
  geom_alluvium(aes(fill = stage1, alpha = on), width = 0.34, colour = NA, curve_type = "sigmoid") +
  geom_stratum(width = 0.34, fill = "white", colour = grey[["dark"]], linewidth = pv_house_lw("frame")) +
  geom_text(stat = "stratum", aes(label = after_stat(stratum)), size = pv_pt2size(7),
            colour = "#1A1A1A", family = house_family()) +
  scale_x_discrete(limits = axis_labels, expand = expansion(add = 0.25)) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.02))) +
  scale_fill_manual(values = pal, name = NULL) +
  scale_alpha_manual(values = c(`TRUE` = 0.85, `FALSE` = 0.25), guide = "none") +
  labs(x = NULL, y = "Patients", caption = footnote) +
  theme_house() +
  theme(legend.position = "top", legend.justification = "left",
        legend.margin = margin(0, 0, 0, 0), legend.box.spacing = unit(1, "mm"),
        plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]],
                                    lineheight = 0.9, margin = margin(t = 0.8, unit = "mm")),
        plot.caption.position = "plot")

if (isTRUE(show_bubbles)) {
  p <- p + geom_point(stat = "stratum", aes(size = after_stat(y)),
                      shape = 21, fill = "white", colour = grey[["dark"]], stroke = 0.3) +
    scale_size_area(max_size = 5, guide = "none")
}

pv_save_house(p, "figure", cells = "2x1")
message("wrote preview.png")
