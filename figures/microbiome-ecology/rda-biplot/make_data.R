# Three habitats, two gradients, ten plant species, five soil variables.
# Writes data.csv (long community) and data_env.csv. Run from this directory.
set.seed(27)
groups <- c("Forest", "Meadow", "Marsh")
n_per <- 16
group <- rep(groups, each = n_per)
n <- length(group)
sample <- sprintf("S%02d", seq_len(n))

g1 <- c(Forest = -1.10, Meadow = 0.15, Marsh = 1.15)[group] + stats::rnorm(n, sd = 0.28)
g2 <- c(Forest = 0.35, Meadow = 1.05, Marsh = -0.85)[group] + stats::rnorm(n, sd = 0.28)

env <- data.frame(
  sample = sample,
  pH = round(6.0 + 0.85 * g1 + stats::rnorm(n, sd = 0.12), 2),
  Moisture = round(40 + 18 * g1 + 4 * g2 + stats::rnorm(n, sd = 2.2), 2),
  Nitrogen = round(2.2 + 0.55 * g1 + 0.65 * g2 + stats::rnorm(n, sd = 0.12), 3),
  Temp = round(16 + 2.4 * g2 + stats::rnorm(n, sd = 0.25), 2),
  OrganicC = round(6.5 - 2.1 * g1 + 1.1 * g2 + stats::rnorm(n, sd = 0.20), 2),
  stringsAsFactors = FALSE
)

species <- c(
  "Quercus", "Fagus", "Pinus", "Poa", "Trifolium",
  "Ranunculus", "Carex", "Typha", "Juncus", "Sphagnum"
)
optima <- rbind(
  c(-1.05, 0.45),
  c(-0.75, 1.00),
  c(-1.25, -0.15),
  c(0.15, 1.15),
  c(0.45, 0.65),
  c(0.05, 0.15),
  c(0.85, -0.15),
  c(1.25, -0.75),
  c(0.95, -1.05),
  c(0.25, -0.95)
)
rownames(optima) <- species

comm_rows <- vector("list", length(species))
for (i in seq_along(species)) {
  d2 <- (g1 - optima[i, 1])^2 + (g2 - optima[i, 2])^2
  lambda <- 16 * exp(-d2 / (2 * 0.75^2))
  comm_rows[[i]] <- data.frame(
    sample = sample,
    group = group,
    taxon = species[[i]],
    abundance = stats::rpois(n, lambda),
    stringsAsFactors = FALSE
  )
}
comm <- do.call(rbind, comm_rows)
site_sum <- tapply(comm$abundance, comm$sample, sum)
if (any(site_sum <= 0)) stop("a site has no individuals")

utils::write.csv(comm, "data.csv", row.names = FALSE)
utils::write.csv(env, "data_env.csv", row.names = FALSE)
message("wrote data.csv and data_env.csv")
