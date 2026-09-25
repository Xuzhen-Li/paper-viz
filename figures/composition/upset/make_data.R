# Presence calls from overlapping latent risk, not a hard membership cut.
# Run from this directory.
set.seed(523)
elements <- sprintf("E%02d", 1:80)
sets <- c("ATAC", "H3K27ac", "H3K4me3", "CTCF", "RNA")
risk <- stats::rnorm(80)
bias <- c(ATAC = 0.2, H3K27ac = 0.55, H3K4me3 = -0.1, CTCF = -0.35, RNA = 0.15)
rows <- lapply(sets, function(s) {
  prob <- stats::plogis(bias[[s]] + 0.85 * risk + stats::rnorm(80, 0, 0.55))
  data.frame(element = elements, set = s, present = stats::rbinom(80, 1, prob))
})
utils::write.csv(do.call(rbind, rows), "data.csv", row.names = FALSE)
message("wrote data.csv")
