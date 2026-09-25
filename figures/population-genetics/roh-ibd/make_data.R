# ROH and IBD segment lengths (Mb) for six populations.
set.seed(113)
pops <- c("Wild N", "Wild S", "Landrace E", "Landrace W", "Cultivar A", "Cultivar B")
# meanlog of length in Mb. Cultivars carry longer ROH.
roh_mu <- c(0.15, 0.05, 0.45, 0.35, 1.15, 1.25)
ibd_mu <- c(-0.25, -0.35, 0.05, 0.00, 0.55, 0.65)
n_each <- 150L
one <- function(pop, mu, kind) {
  len <- rlnorm(n_each, meanlog = mu, sdlog = 0.55)
  len <- pmin(28, pmax(0.25, len))
  data.frame(pop = pop, kind = kind, length_mb = round(len, 3), stringsAsFactors = FALSE)
}
rows <- lapply(seq_along(pops), function(i) {
  rbind(one(pops[i], roh_mu[i], "ROH"), one(pops[i], ibd_mu[i], "IBD"))
})
utils::write.csv(do.call(rbind, rows), "data.csv", row.names = FALSE)
message("wrote data.csv")
