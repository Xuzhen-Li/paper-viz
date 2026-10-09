# Simulated data for the house grid mosaic: one long table, one block per panel. Run from this directory.
# panel: scatter | hist | line | bar | box | comp | track; group / x / y depend on the panel (see meta.yaml).
set.seed(20261009)
blocks <- list()

# a scatter: leaf N (%) vs net photosynthesis
n <- 60
leaf_n <- stats::runif(n, 1.2, 3.6)
blocks$scatter <- data.frame(panel = "scatter", group = "", x = round(leaf_n, 3),
                             y = round(4 + 5.2 * leaf_n + stats::rnorm(n, 0, 2.2), 3))

# b histogram: berry diameter (mm)
blocks$hist <- data.frame(panel = "hist", group = "", x = NA, y = round(stats::rnorm(400, 14.5, 1.6), 3))

# c line: shoot length over days, two treatments x 6 plants
days <- seq(0, 42, 7)
blocks$line <- do.call(rbind, lapply(c("Control", "Warmed"), function(g) {
  k <- if (g == "Control") 0.075 else 0.105
  do.call(rbind, lapply(1:6, function(i) {
    data.frame(panel = "line", group = g, x = days,
               y = round(120 / (1 + exp(-k * (days - 21))) + stats::rnorm(length(days), 0, 4), 3))
  }))
}))

# d bar: relative expression, four treatments x 5 replicates
mu <- c(Control = 1, Drought = 2.1, Heat = 1.6, Both = 3.2)
blocks$bar <- do.call(rbind, lapply(names(mu), function(g)
  data.frame(panel = "bar", group = g, x = NA, y = round(stats::rnorm(5, mu[[g]], 0.25 * mu[[g]]), 3))))

# e box: soil pH at three sites
ph <- c(North = 6.1, Valley = 6.8, Ridge = 5.6)
blocks$box <- do.call(rbind, lapply(names(ph), function(g)
  data.frame(panel = "box", group = g, x = NA, y = round(stats::rnorm(25, ph[[g]], 0.35), 3))))

# f composition: land-cover share (%) at six sites
cover <- c("Crop", "Forest", "Grass", "Other")
sites <- paste0("S", 1:6)
blocks$comp <- do.call(rbind, lapply(sites, function(s) {
  w <- stats::rgamma(4, shape = c(6, 4, 3, 1.2))
  data.frame(panel = "comp", group = cover, x = s, y = round(100 * w / sum(w), 2))
}))

# g track: genome-wide association, 8 chromosomes, -log10 P
chr_len <- c(31, 27, 24, 22, 20, 18, 16, 14)  # Mb
blocks$track <- do.call(rbind, lapply(seq_along(chr_len), function(i) {
  pos <- sort(stats::runif(220, 0, chr_len[i]))
  lp <- -log10(stats::runif(220))
  if (i == 3) lp <- lp + 9 * exp(-((pos - 12) / 0.8)^2)   # one peak on chr 3
  if (i == 6) lp <- lp + 5 * exp(-((pos - 7) / 0.6)^2)    # a weaker one on chr 6
  data.frame(panel = "track", group = paste0("chr", i), x = round(pos, 4), y = round(lp, 3))
}))

d <- do.call(rbind, blocks)
utils::write.csv(d, "data.csv", row.names = FALSE)
message("wrote data.csv rows=", nrow(d))
