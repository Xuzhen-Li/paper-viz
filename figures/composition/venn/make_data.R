# Set membership. Each id joins a random non-empty subset; counts are summed in plot.R.
# Run from this directory.
set.seed(522)
sets <- c("RNA-seq", "Proteome", "ChIP")
ids <- sprintf("G%02d", 1:40)
rows <- lapply(ids, function(id) {
  k <- sample.int(3, 1, prob = c(0.5, 0.35, 0.15))
  picked <- sample(sets, k)
  data.frame(set = picked, id = id)
})
utils::write.csv(do.call(rbind, rows), "data.csv", row.names = FALSE)
message("wrote data.csv")
