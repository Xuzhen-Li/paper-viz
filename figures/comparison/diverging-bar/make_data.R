# Signed percentage changes for 20 markers. Run from this directory.
set.seed(48)
item <- sprintf("M%02d", 1:20)
value <- c(rnorm(9, -18, 7), rnorm(11, 16, 8))
value <- round(value, 1)
value[abs(value) < 3] <- value[abs(value) < 3] + sample(c(-6, 6), sum(abs(value) < 3), replace = TRUE)
class <- ifelse(value >= 0, "Increased", "Decreased")
utils::write.csv(
  data.frame(item = item, value = value, class = class),
  "data.csv",
  row.names = FALSE
)
message("wrote data.csv")
