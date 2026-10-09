# Simulated log2 fold changes of 10 genes after 1, 3 and 7 days of drought or heat. Run from this directory.
set.seed(20261014)
genes <- c("VvSWEET10", "VvAGL11", "VvMYBA1", "VvGAI1", "VvCEB1", "VvIAA19", "VvNAC26", "VvERF045",
           "VvHSP17", "VvDREB2")
stress <- c("Drought", "Heat")
days <- c(1, 3, 7)
base <- c(1.6, 0.9, -1.4, -0.8, 0.5, -1.9, 1.2, 0.2, 2.3, 1.9)
heat_shift <- c(-0.6, 0.4, 0.8, -0.3, 0.9, 0.6, -0.9, -1.3, 0.6, -1.5)
d <- expand.grid(gene = genes, stress = stress, day = days, stringsAsFactors = FALSE)
gi <- match(d$gene, genes)
ramp <- c(0.45, 0.8, 1)[match(d$day, days)]
d$log2fc <- round((base[gi] + ifelse(d$stress == "Heat", heat_shift[gi], 0)) * ramp +
                    stats::rnorm(nrow(d), 0, 0.18), 2)
utils::write.csv(d, "data.csv", row.names = FALSE)
message("wrote data.csv rows=", nrow(d))
