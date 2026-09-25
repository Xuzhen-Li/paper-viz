# Ranked feature scores, not every large score is marked. Run from this directory.
set.seed(50)
item <- sprintf("F%02d", 1:25)
value <- sort(round(rexp(25, rate = 0.45) + runif(25, 0.2, 1.1), 2))
signif <- value > stats::quantile(value, 0.72)
signif[22] <- FALSE
signif[14] <- TRUE
utils::write.csv(
  data.frame(item = item, value = value, signif = signif),
  "data.csv",
  row.names = FALSE
)
message("wrote data.csv")
