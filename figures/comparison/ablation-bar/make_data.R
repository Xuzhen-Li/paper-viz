# Simulated ablation study: one full model and five variants with one component removed,
# scored on a held-out set with five random seeds each. Run from this directory.
set.seed(2026)
variants <- c("Full model", "w/o attention", "w/o pretraining", "w/o augmentation",
              "w/o multi-scale", "w/o contrastive loss")
true_mean <- c(84.6, 80.9, 76.2, 83.1, 82.0, 79.4)   # accuracy (%)
rows <- list()
for (i in seq_along(variants)) {
  rows[[i]] <- data.frame(
    variant = variants[i],
    seed = 1:5,
    score = round(true_mean[i] + rnorm(5, 0, 0.6), 2),
    stringsAsFactors = FALSE
  )
}
utils::write.csv(do.call(rbind, rows), "data.csv", row.names = FALSE)
message("wrote data.csv")
