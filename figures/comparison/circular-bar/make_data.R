# Sixteen sites, two cohorts. Lognormal scores with cohort shift and noise.
# Run from this directory.
set.seed(7077)
sites <- c(
  "Liver", "Lung", "Colon", "Breast", "Skin", "Kidney", "Brain", "Pancreas",
  "Stomach", "Ovary", "Prostate", "Bladder", "Thyroid", "Uterus", "Esophagus", "Blood"
)
groups <- c("Primary", "Metastasis")
rows <- vector("list", length(sites) * length(groups))
k <- 1L
for (s in seq_along(sites)) {
  base <- stats::rlnorm(1, meanlog = log(12), sdlog = 0.28)
  for (g in groups) {
    shift <- if (g == "Metastasis") stats::rnorm(1, 1.18, 0.12) else stats::rnorm(1, 1, 0.08)
    rows[[k]] <- data.frame(
      category = sites[s],
      group = g,
      value = round(base * shift * stats::rlnorm(1, 0, 0.08), 2)
    )
    k <- k + 1L
  }
}
utils::write.csv(do.call(rbind, rows), "data.csv", row.names = FALSE)
message("wrote data.csv")
