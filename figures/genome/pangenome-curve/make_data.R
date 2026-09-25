# Open plant pangenome: three compartments and a 40-genome accumulation curve.
set.seed(205)

core_n <- 14000L
shell_n <- 18600L
cloud_n <- 12400L
comp <- data.frame(
  compartment = c("Core", "Shell", "Cloud"),
  n_families = c(core_n, shell_n, cloud_n)
)
utils::write.csv(comp, "data_compartment.csv", row.names = FALSE)

n_genomes <- 1:40
pan1 <- 22000
alpha <- 0.19
pan <- pan1 * n_genomes^alpha
pan <- pan + stats::rnorm(length(n_genomes), 0, 180 + n_genomes * 8)
pan <- cummax(round(pan))
pan[1] <- pan1
core <- 13500 + (pan1 - 13500) * n_genomes^(-0.42)
core <- core + stats::rnorm(length(n_genomes), 0, 120)
core <- round(pmin(cummin(core), pan - 800))
core[1] <- pan1
growth <- data.frame(
  step = n_genomes,
  n_genomes = n_genomes,
  pan = pan,
  core = core
)
utils::write.csv(growth, "data_growth.csv", row.names = FALSE)
message("wrote compartment and growth tables")
