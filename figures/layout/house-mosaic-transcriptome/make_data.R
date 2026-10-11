# Simulated RNA-seq summary of a grapevine drought trial (well-watered WW vs severe drought SD).
# Writes data.csv (PCA scores of 16 libraries), data_deg.csv (DEG counts per tissue),
# data_heatmap.csv (z-scores of 40 top DEGs), data_go.csv (GO enrichment) and
# data_upset.csv (tissue membership of up-regulated DEGs). Run from this directory.
set.seed(23)
tis <- c("Leaf", "Root", "Shoot tip", "Berry skin", "Seed")

# PCA: 2 tissues x 2 treatments x 4 libraries
smp <- expand.grid(rep = 1:4, treatment = c("WW", "SD"), tissue = c("Leaf", "Root"), stringsAsFactors = FALSE)
smp$pc1 <- ifelse(smp$tissue == "Leaf", -18, 20) + stats::rnorm(nrow(smp), 0, 3)
smp$pc2 <- ifelse(smp$treatment == "SD", 9, -8) * ifelse(smp$tissue == "Leaf", 1, 0.75) + stats::rnorm(nrow(smp), 0, 2.4)
smp$sample <- seq_len(nrow(smp))
utils::write.csv(data.frame(sample = smp$sample, tissue = smp$tissue, treatment = smp$treatment, rep = smp$rep,
                            pc1 = round(smp$pc1, 3), pc2 = round(smp$pc2, 3)), "data.csv", row.names = FALSE)

# DEG counts (SD vs WW) per tissue
deg <- data.frame(tissue = rep(tis, 2), direction = rep(c("Up", "Down"), each = 5),
                  n = c(812, 1046, 433, 521, 198, 655, 903, 310, 402, 151))
utils::write.csv(deg, "data_deg.csv", row.names = FALSE)

# Heatmap: 40 DEGs in 3 clusters x 16 libraries, z-scores clipped to +/-2
cl <- rep(c("Up in both", "Up in leaf", "Down in both"), c(16, 12, 12))
z <- t(sapply(cl, function(k) {
  mu <- switch(k, "Up in both" = ifelse(smp$treatment == "SD", 1.1, -1.1),
               "Up in leaf" = ifelse(smp$treatment == "SD" & smp$tissue == "Leaf", 1.6, -0.5),
               "Down in both" = ifelse(smp$treatment == "SD", -1.1, 1.1))
  mu + stats::rnorm(nrow(smp), 0, 0.45)
}))
utils::write.csv(data.frame(gene = rep(seq_along(cl), nrow(smp)), cluster = rep(cl, nrow(smp)),
                            sample = rep(smp$sample, each = length(cl)), z = round(pmax(-2, pmin(2, as.vector(z))), 3)),
                 "data_heatmap.csv", row.names = FALSE)

# GO enrichment of DEGs: odds ratio with 95% CI
go <- data.frame(term = c("ABA response", "Water deficit", "Raffinose synth.", "LEA proteins",
                          "Proline synth.", "Photosynthesis", "Cell wall", "Aquaporins"),
                 or = c(4.8, 4.1, 3.6, 3.2, 2.7, 0.32, 0.45, 0.55))
go$lo <- round(go$or / exp(stats::runif(8, 0.25, 0.45)), 3); go$hi <- round(go$or * exp(stats::runif(8, 0.25, 0.45)), 3)
utils::write.csv(go, "data_go.csv", row.names = FALSE)

# UpSet: up-regulated DEGs only. One membership matrix over a gene pool; each tissue's members
# are drawn without replacement with exactly the Up count above (shared latent programmes make
# the tissues overlap), so set sizes equal data_deg.csv by construction.
up_n <- deg$n[deg$direction == "Up"]
pool <- 2600; lat <- matrix(stats::rnorm(pool * 2), pool)
w <- cbind(stats::plogis(-0.2 + 1.6 * lat[, 1]), stats::plogis(0.2 + 1.5 * lat[, 1] + 0.8 * lat[, 2]),
           stats::plogis(-0.6 + 1.4 * lat[, 1]), stats::plogis(-0.4 + 1.3 * lat[, 2]), stats::plogis(-0.8 + 1.2 * lat[, 2]))
mm <- sapply(seq_along(tis), function(k) { v <- integer(pool); v[sample.int(pool, up_n[k], prob = w[, k])] <- 1L; v })
colnames(mm) <- tis
mm <- mm[rowSums(mm) > 0, ]
utils::write.csv(data.frame(gene = sprintf("g%04d", seq_len(nrow(mm))), mm, check.names = FALSE), "data_upset.csv", row.names = FALSE)
