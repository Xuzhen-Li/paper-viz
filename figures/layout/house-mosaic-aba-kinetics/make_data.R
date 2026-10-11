# Simulated ABA-pathway expression data for the grapevine drought trial (WW vs SD).
# data.csv: leaf log2 fold change over time for three genes (mean and s.e.);
# data_psi.csv: expression vs stem water potential (28 vines per gene);
# data_raincloud.csv: VvNCED3 expression by tissue and treatment (20 vines per group);
# data_fc.csv: log2 FC of all leaf and root DEGs (counts as in house-mosaic-transcriptome).
# Run from this directory.
set.seed(20261014)

hrs <- c(0, 6, 12, 24, 48, 96, 168)
kin <- expand.grid(hours = hrs, gene = c("VvNCED3", "VvRD29B", "VvPIP2;1"), stringsAsFactors = FALSE)
kin$log2fc <- with(kin, ifelse(gene == "VvNCED3", 5.2 * (1 - exp(-hours / 20)) * exp(-hours / 130),
                        ifelse(gene == "VvRD29B", 3.6 * (1 - exp(-hours / 50)), -2.1 * (1 - exp(-hours / 30)))))
kin$se <- 0.15 + 0.04 * abs(kin$log2fc)
kin[c("log2fc", "se")] <- round(kin[c("log2fc", "se")], 3)
utils::write.csv(kin, "data.csv", row.names = FALSE)

slope <- c(VvNCED3 = -3.4, VvRD29B = -2.6, "VvPIP2;1" = 1.6, VvLEA4 = -2.0)
sm <- expand.grid(vine = 1:28, gene = names(slope), stringsAsFactors = FALSE)
sm$psi <- stats::runif(nrow(sm), -1.7, -0.3)
sm$expression <- 6 + slope[sm$gene] * (sm$psi + 1) + stats::rnorm(nrow(sm), 0, 0.5)
sm[c("psi", "expression")] <- round(sm[c("psi", "expression")], 3)
utils::write.csv(sm, "data_psi.csv", row.names = FALSE)

vi <- data.frame(treatment = rep(c("WW", "SD"), each = 40), tissue = rep(rep(c("Leaf", "Root"), each = 20), 2))
vi$expression <- round(4 + ifelse(vi$treatment == "SD", 2.4, 0) + ifelse(vi$tissue == "Root", 0.8, 0) + stats::rnorm(80, 0, 0.6), 3)
vi$jitter <- round(stats::runif(80), 3)      # vertical position of the raw points under each cloud (0-1)
utils::write.csv(vi, "data_raincloud.csv", row.names = FALSE)

n <- c(leaf_up = 812, leaf_down = 655, root_up = 1046, root_down = 903)
fc <- data.frame(tissue = rep(c("Leaf", "Root"), c(n[["leaf_up"]] + n[["leaf_down"]], n[["root_up"]] + n[["root_down"]])),
                 log2fc = c(stats::rnorm(n[["leaf_up"]], 1.9, 0.7), -stats::rnorm(n[["leaf_down"]], 1.7, 0.6),
                            stats::rnorm(n[["root_up"]], 2.2, 0.8), -stats::rnorm(n[["root_down"]], 2.0, 0.7)))
fc$log2fc <- round(fc$log2fc, 3)
utils::write.csv(fc, "data_fc.csv", row.names = FALSE)
