# Expression plus optional geneset and module-trait tables.
# Values stay continuous; grouping and colour cuts happen in plot.R.
# Run from this directory.
set.seed(515)
features <- c(
  "TP53", "MDM2", "CDKN1A", "BAX", "GADD45A", "BBC3", "FAS", "CASP3", "BCL2", "MCL1",
  "CDK1", "CCNB1", "CCNA2", "MKI67", "TOP2A", "PCNA", "MCM2", "E2F1", "AURKA", "PLK1",
  "IL6", "CXCL8", "TNF", "STAT1", "ISG15", "IFIT1", "MX1", "OAS1", "CCL2", "NFKB1",
  "GAPDH", "ACTB", "HSP90AB1", "LDHA", "PKM", "ENO1", "ALDOA", "TPI1", "PGK1", "PPIA"
)
samples <- sprintf("S%02d", 1:20)
group <- rep(c("Tumor", "Adjacent", "Normal", "Treated"), each = 5)
names(group) <- samples
mod <- list(1:10, 11:20, 21:30, 31:40)
boost <- c(Tumor = 1.15, Adjacent = 0.35, Normal = -0.85, Treated = -0.25)
mat <- matrix(stats::rnorm(40 * 20, 0, 0.62), 40, 20, dimnames = list(features, samples))
for (i in seq_along(mod)) {
  gname <- names(boost)[i]
  cols <- samples[group == gname]
  mat[mod[[i]], cols] <- mat[mod[[i]], cols] + boost[[i]]
  mat[mod[[i]], ] <- mat[mod[[i]], ] + stats::rnorm(1, 0, 0.15)
}
df <- data.frame(
  feature = rep(features, times = 20),
  sample = rep(samples, each = 40),
  value = as.vector(mat),
  group = rep(group[samples], each = 40),
  stringsAsFactors = FALSE
)
utils::write.csv(df, "data.csv", row.names = FALSE)

sets <- c("p53 pathway", "Cell cycle", "Interferon", "Glycolysis")
gs <- matrix(stats::rnorm(4 * 20, 0, 0.45), 4, 20, dimnames = list(sets, samples))
for (i in seq_along(sets)) {
  gs[i, group == names(boost)[i]] <- gs[i, group == names(boost)[i]] + 1
}
gs_df <- data.frame(
  feature = rep(sets, times = 20),
  sample = rep(samples, each = 4),
  value = as.vector(gs),
  group = rep(group[samples], each = 4),
  stringsAsFactors = FALSE
)
utils::write.csv(gs_df, "data_geneset.csv", row.names = FALSE)

traits <- c("Stage", "Grade", "Ki67", "Size")
modules <- c("M1", "M2", "M3", "M4")
r <- matrix(stats::rnorm(16, 0, 0.28), 4, 4, dimnames = list(modules, traits))
diag_boost <- c(0.55, 0.48, -0.42, 0.36)
for (i in seq_len(4)) r[i, i] <- r[i, i] + diag_boost[i]
r <- pmax(pmin(r, 0.92), -0.92)
mt <- expand.grid(module = modules, trait = traits, stringsAsFactors = FALSE)
mt$r <- as.vector(r)
utils::write.csv(mt, "data_module.csv", row.names = FALSE)
message("wrote data.csv data_geneset.csv data_module.csv")
