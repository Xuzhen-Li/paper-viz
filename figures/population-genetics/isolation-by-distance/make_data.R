# Isolation by distance: geographic km vs Rousset's Fst/(1-Fst).
set.seed(112)
regions <- c("North", "Central", "South")
slope <- c(North = 0.00009, Central = 0.00011, South = 0.00016)
n <- c(North = 70, Central = 70, South = 60)
rows <- lapply(regions, function(r) {
  dist <- runif(n[[r]], if (r == "South") 20 else 40, if (r == "South") 900 else 1600)
  y <- 0.012 + slope[[r]] * dist + rnorm(n[[r]], 0, 0.028)
  data.frame(
    dist_km = round(dist, 1),
    fst_linear = round(pmax(0.001, y), 4),
    region = r,
    stringsAsFactors = FALSE
  )
})
utils::write.csv(do.call(rbind, rows), "data.csv", row.names = FALSE)
message("wrote data.csv")
