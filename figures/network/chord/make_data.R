# Eight cell groups and 40 directed flows.
set.seed(309)

groups <- c("Tcell", "Bcell", "NK", "Mono", "Mac", "DC", "Neutro", "Stroma")
flows <- list()
for (k in seq_len(40L)) {
  a <- sample(groups, 1L)
  b <- sample(setdiff(groups, a), 1L)
  # a few strong pathways, the rest smaller and noisy
  base <- if (a %in% c("Mac", "DC") && b %in% c("Tcell", "NK")) 8 else 2
  val <- stats::rgamma(1, shape = 2, scale = base)
  flows[[k]] <- data.frame(source = a, target = b, value = round(val, 2), stringsAsFactors = FALSE)
}
out <- do.call(rbind, flows)
# collapse duplicate pairs by summing, then if under 40 split the largest
key <- paste(out$source, out$target, sep = ">")
agg <- stats::aggregate(value ~ source + target, out, sum)
if (nrow(agg) > 40L) agg <- agg[order(-agg$value), , drop = FALSE][seq_len(40L), ]
utils::write.csv(agg, "data.csv", row.names = FALSE)
