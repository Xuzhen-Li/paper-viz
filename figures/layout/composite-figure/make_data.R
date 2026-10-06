# One simulated experiment, four panels, one data.csv. Run from this directory.
set.seed(2401)

groups <- c("Control", "Low", "High")
g_mean <- c(Control = 2.1, Low = 3.3, High = 4.5)
g_slope <- c(Control = 0.42, Low = 0.55, High = 0.70)
g_int <- c(Control = 1.0, Low = 1.35, High = 1.9)

blank <- function(panel, group, x, y, class, item) {
  data.frame(
    panel = panel,
    group = group,
    x = x,
    y = y,
    class = class,
    item = item,
    stringsAsFactors = FALSE
  )
}

n_a <- 22L
parts_a <- lapply(groups, function(g) {
  x <- stats::rnorm(n_a, g_mean[[g]], 0.48)
  y <- g_int[[g]] + g_slope[[g]] * x + stats::rnorm(n_a, 0, 0.38)
  blank("A", rep(g, n_a), round(x, 3), round(y, 3), NA_character_, NA_character_)
})

tissues <- c("Liver", "Spleen", "Lung", "Kidney")
base_b <- c(Liver = 8.5, Spleen = 6.2, Lung = 11.0, Kidney = 7.4)
mult_b <- c(Control = 1, Low = 1.28, High = 1.62)
parts_b <- lapply(tissues, function(tissue) {
  do.call(rbind, lapply(groups, function(g) {
    y <- base_b[[tissue]] * mult_b[[g]] * stats::runif(1, 0.96, 1.04)
    blank("B", g, NA_real_, round(y, 2), tissue, NA_character_)
  }))
})

days <- 0:5
traj <- list(
  Control = c(1.10, 1.15, 1.20, 1.18, 1.22, 1.25),
  Low = c(1.05, 1.40, 1.90, 2.30, 2.55, 2.70),
  High = c(1.20, 1.80, 2.60, 3.30, 3.70, 3.85)
)
parts_c <- lapply(groups, function(g) {
  y <- traj[[g]] + stats::rnorm(length(days), 0, 0.06)
  blank("C", rep(g, length(days)), days, round(y, 3), NA_character_, NA_character_)
})

genes <- c("Actb", "Myc", "Tp53", "Vegfa", "Cdkn1a")
samples <- c("C1", "C2", "L1", "L2", "H1", "H2")
samp_g <- c(C1 = "Control", C2 = "Control", L1 = "Low", L2 = "Low", H1 = "High", H2 = "High")
gene_eff <- rbind(
  Actb = c(Control = 0.05, Low = 0.08, High = 0.02),
  Myc = c(Control = -0.40, Low = 0.35, High = 1.15),
  Tp53 = c(Control = 0.95, Low = 0.15, High = -0.70),
  Vegfa = c(Control = -0.20, Low = 0.85, High = 1.05),
  Cdkn1a = c(Control = 0.55, Low = 0.20, High = -0.85)
)
parts_d <- lapply(genes, function(gene) {
  do.call(rbind, lapply(samples, function(s) {
    g <- unname(samp_g[[s]])
    val <- gene_eff[gene, g] + stats::rnorm(1, 0, 0.12)
    blank("D", g, NA_real_, round(val, 3), gene, s)
  }))
})

out <- do.call(rbind, c(parts_a, parts_b, parts_c, parts_d))
utils::write.csv(out, "data.csv", row.names = FALSE, na = "")
message("wrote data.csv")
