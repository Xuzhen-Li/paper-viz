# Kaplan-Meier curves (house style): step lines per arm with censor ticks, arm names and
# median survival written at the curve ends, log-rank P in the panel. survival only computes.
# Reads data.csv only. Run from this directory.
source("../../../styles/r/theme_house.R")
library(ggplot2)

show_censor <- TRUE
arm_levels <- c("Control", "Treatment")
hp <- pv_palette("house"); grey <- pv_palette("house_grey")
# blue and red are both >= 3:1 on white, so the arm labels keep the line colour
cols <- stats::setNames(c(hp[["blue"]], hp[["red"]]), arm_levels)
footnote <- "Simulated data for illustration; not biological results"

df <- utils::read.csv("data.csv", stringsAsFactors = FALSE)
df$arm <- factor(df$arm, levels = arm_levels)
fit <- survival::survfit(survival::Surv(time, status) ~ arm, data = df)
sf <- summary(fit, censored = TRUE)
arm <- factor(sub("^arm=", "", sf$strata), levels = arm_levels)
curve <- data.frame(time = sf$time, surv = sf$surv, arm = arm, n_censor = sf$n.censor)
# start every curve at (0, 1)
curve <- rbind(data.frame(time = 0, surv = 1, arm = factor(arm_levels, levels = arm_levels), n_censor = 0), curve)
curve <- curve[order(curve$arm, curve$time), ]
cens <- curve[curve$n_censor > 0, , drop = FALSE]
lr <- survival::survdiff(survival::Surv(time, status) ~ arm, data = df)
p_lr <- stats::pchisq(lr$chisq, df = length(arm_levels) - 1, lower.tail = FALSE)
med <- summary(fit)$table[, "median"]
names(med) <- sub("^arm=", "", names(med))
ends <- do.call(rbind, lapply(arm_levels, function(a) {
  d <- curve[curve$arm == a, ]
  data.frame(arm = factor(a, levels = arm_levels), time = max(d$time), surv = d$surv[nrow(d)],
             n = sum(df$arm == a), med = med[[a]])
}))
ends$lab <- sprintf("%s (n = %d)\nmedian %s", ends$arm, ends$n,
                    ifelse(is.na(ends$med), "not reached", sprintf("%.1f mo", ends$med)))
x_max <- max(curve$time)
# keep the end labels apart
ends <- ends[order(ends$surv), ]
for (i in seq_len(nrow(ends))[-1]) ends$surv[i] <- max(ends$surv[i], ends$surv[i - 1] + 0.2)

p <- ggplot(curve, aes(time, surv, colour = arm)) +
  geom_step(linewidth = pv_house_lw("main"))
if (isTRUE(show_censor)) {
  # censor marks as short vertical segments (a "|" point shape would be drawn as a text glyph)
  tick_h <- 0.025
  p <- p + geom_segment(data = cens, aes(x = time, xend = time, y = surv - tick_h, yend = surv + tick_h),
                        linewidth = pv_house_lw("minor"))
}
p <- p +
  geom_text(data = ends, aes(x = x_max * 1.02, y = surv, label = lab), hjust = 0, vjust = 0.5,
            lineheight = 0.9) +
  annotate("text", x = x_max * 0.02, y = 0.04, hjust = 0, vjust = 0,
           label = sprintf("'Log-rank '*%s", pv_fmt_p(p_lr)), parse = TRUE) +
  scale_colour_manual(values = cols, guide = "none") +
  scale_x_continuous(breaks = seq(0, 40, 10)) +
  scale_y_continuous(breaks = seq(0, 1, 0.25)) +
  coord_cartesian(xlim = c(0, x_max * 1.42), ylim = c(0, 1.02), expand = FALSE) +
  labs(x = "Time (months)", y = "Survival probability", caption = footnote) +
  theme_house() +
  theme(plot.caption = element_text(size = 7, hjust = 0, colour = grey[["mid"]],
                                    margin = margin(t = 0.8, unit = "mm")),
        plot.caption.position = "plot")

pv_save_house(p, "figure", cells = "2x1")
message("wrote preview.png")
