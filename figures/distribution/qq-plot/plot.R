# Normal QQ plot (house style): shape-21 points, dashed quartile reference line,
# Shapiro-Wilk P and n in the panel. Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

point_size <- 1.6     # 400 points: smaller shape-21 points
point_alpha <- 0.7    # STYLE §5: 200-2000 points -> alpha 0.6-0.8
show_ref_line <- TRUE

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
x <- sort(as.numeric(df$value))
n <- length(x)
# Blom plotting positions
prob <- (seq_len(n) - 0.375) / (n + 0.25)
qq <- data.frame(theoretical = stats::qnorm(prob), sample = x)
hp <- pv_palette("house"); grey <- pv_palette("house_grey")
footnote <- "Simulated data for illustration;\nnot biological results"
sw <- stats::shapiro.test(x)$p.value

p <- ggplot(qq, aes(theoretical, sample))
if (isTRUE(show_ref_line)) {
  qy <- stats::quantile(x, c(0.25, 0.75), names = FALSE, type = 7)
  qx <- stats::qnorm(c(0.25, 0.75))
  slope <- diff(qy) / diff(qx)
  p <- p + geom_abline(intercept = qy[1] - slope * qx[1], slope = slope, linetype = "22",
                       linewidth = pv_house_lw("ref"), colour = "black")
}
p <- p +
  geom_point(shape = HOUSE_POINT$shape, size = point_size, stroke = HOUSE_POINT$stroke,
             colour = "black", fill = hp[["blue"]], alpha = point_alpha) +
  annotate("text", x = min(qq$theoretical), y = Inf, hjust = 0, vjust = 1.25, parse = TRUE,
           label = paste0("'Shapiro-Wilk '*", pv_fmt_p(sw))) +
  annotate("text", x = min(qq$theoretical), y = Inf, hjust = 0, vjust = 2.6, label = sprintf("n = %d", n)) +
  scale_y_continuous(expand = expansion(mult = c(0.04, 0.2))) +
  labs(x = "Theoretical quantiles", y = "Sample quantiles", caption = footnote) +
  theme_house() +
  theme(plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]], lineheight = 0.9,
                                    margin = margin(t = 0.8, unit = "mm")),
        plot.caption.position = "plot")

pv_save_house(p, "figure", cells = "1x1")
message("wrote preview.png")
