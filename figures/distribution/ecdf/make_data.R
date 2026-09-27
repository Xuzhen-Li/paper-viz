# Simulated multi-group samples for ECDF. Run from this directory.
set.seed(33)
groups <- c("Group A", "Group B", "Group C")
n_each <- c(180, 160, 140)
means <- c(0.0, 0.55, -0.35)
sds <- c(1.0, 0.85, 1.15)
parts <- lapply(seq_along(groups), function(i) {
  data.frame(
    group = groups[[i]],
    value = rnorm(n_each[[i]], mean = means[[i]], sd = sds[[i]]) +
      rnorm(n_each[[i]], 0, 0.05),
    stringsAsFactors = FALSE
  )
})
df <- do.call(rbind, parts)
df$sample <- sprintf("S%04d", seq_len(nrow(df)))
df$value <- round(df$value, 6)
df <- df[, c("sample", "group", "value")]
utils::write.csv(df, "data.csv", row.names = FALSE)
message("wrote data.csv")
