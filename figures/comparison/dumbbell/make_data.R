# Fifteen sites measured at two stages. Run from this directory.
set.seed(49)
item <- sprintf("Site %02d", 1:15)
base <- round(runif(15, 22, 68), 1)
delta <- rnorm(15, 8, 7)
delta[c(3, 7, 12)] <- -abs(rnorm(3, 6, 2))
follow <- round(pmax(8, base + delta), 1)
utils::write.csv(
  data.frame(
    item = rep(item, each = 2),
    stage = rep(c("Baseline", "Week 12"), times = 15),
    value = as.vector(rbind(base, follow))
  ),
  "data.csv",
  row.names = FALSE
)
message("wrote data.csv")
