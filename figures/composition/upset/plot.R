# UpSet bars and dot matrix (house style). Choose how many sets and how to sort.
# Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)
library(patchwork)

n_sets <- 5
sort_by <- "degree"
max_intersections <- 16
set_levels <- c("ATAC", "H3K27ac", "H3K4me3", "CTCF", "RNA")
grey <- pv_palette("house_grey")
footnote <- "Simulated data for illustration; not biological results"

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
use <- set_levels[seq_len(min(n_sets, length(set_levels)))]
df <- df[df$set %in% use, , drop = FALSE]
df$set <- factor(df$set, levels = use)
wide <- reshape(df, idvar = "element", timevar = "set", direction = "wide")
colnames(wide) <- sub("^present\\.", "", colnames(wide))
wide <- wide[rowSums(wide[, use, drop = FALSE]) > 0, , drop = FALSE]
bits <- as.matrix(wide[, use, drop = FALSE])
code <- apply(bits, 1, paste0, collapse = "")
tab <- aggregate(wide$element, by = list(code = code), FUN = length)
colnames(tab)[2] <- "n"
tab$degree <- nchar(gsub("0", "", tab$code))
if (sort_by == "degree") {
  tab <- tab[order(tab$degree, tab$n, decreasing = TRUE), ]
} else {
  tab <- tab[order(tab$n, decreasing = TRUE), ]
}
tab <- head(tab, max_intersections)
tab$code <- factor(tab$code, levels = rev(tab$code))

set_n <- sapply(use, function(s) sum(wide[[s]]))
set_df <- data.frame(set = factor(use, levels = rev(use)), n = set_n[use])
set_lab <- setNames(sprintf("%s (%d)", use, set_n[use]), use)

dot <- do.call(rbind, lapply(seq_len(nrow(tab)), function(i) {
  on <- strsplit(as.character(tab$code[i]), "")[[1]] == "1"
  data.frame(code = tab$code[i], set = factor(use, levels = rev(use)), on = on)
}))
on_pts <- dot[dot$on, , drop = FALSE]

p_bar <- ggplot(tab, aes(code, n)) +
  geom_col(fill = grey[["dark"]], width = 0.72) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.05))) +
  labs(x = NULL, y = "Intersection") +
  theme_house() +
  theme(axis.text.x = element_blank(), axis.ticks.x = element_blank(),
        plot.margin = margin(1, 1, 0, 1, "mm"))

p_dot <- ggplot(dot, aes(code, set)) +
  geom_line(data = on_pts, aes(code, set, group = code), linewidth = pv_house_lw("main"),
            colour = grey[["dark"]]) +
  geom_point(aes(colour = on), shape = 16, size = 2.1) +
  scale_colour_manual(values = c(`TRUE` = grey[["dark"]], `FALSE` = grey[["light"]]), guide = "none") +
  scale_y_discrete(labels = set_lab[rev(use)]) +
  labs(x = NULL, y = NULL) +
  theme_house() +
  theme(axis.text.x = element_blank(), axis.ticks.x = element_blank(),
        axis.line.x = element_blank(), axis.text.y = element_text(size = 7),
        plot.margin = margin(0, 1, 0, 1, "mm"))

p <- p_bar / p_dot + plot_layout(heights = c(1, 1)) +
  plot_annotation(caption = footnote,
                  theme = theme(text = element_text(family = house_family()),
                                plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]],
                                                            lineheight = 0.9, margin = margin(t = 0.8, unit = "mm")),
                                plot.caption.position = "plot"))

pv_save_house(p, "figure", cells = "2x1")
message("wrote preview.png")
