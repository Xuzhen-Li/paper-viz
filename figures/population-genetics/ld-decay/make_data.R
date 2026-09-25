# Mean r^2 in distance bins for four populations.
set.seed(106)
pops <- c("Wild N", "Landrace E", "Cultivar A", "Cultivar B")
# half-decay distance (kb), r2 at 1 kb, background r2
half <- c(8, 28, 70, 110)
start <- c(0.52, 0.60, 0.68, 0.74)
bg <- c(0.04, 0.07, 0.11, 0.14)
dist <- round(exp(seq(log(1), log(400), length.out = 30)), 1)
rows <- lapply(seq_along(pops), function(i) {
  decay <- bg[i] + (start[i] - bg[i]) * exp(-dist / half[i])
  r2 <- decay + rnorm(length(dist), 0, 0.012)
  r2 <- pmin(0.95, pmax(0.01, r2))
  data.frame(pop = pops[i], dist_kb = dist, r2 = round(r2, 4), stringsAsFactors = FALSE)
})
utils::write.csv(do.call(rbind, rows), "data.csv", row.names = FALSE)
message("wrote data.csv")
