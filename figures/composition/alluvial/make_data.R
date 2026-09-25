# Alluvial flows. Highlighting is done in plot.R from the stage labels.
# Run from this directory.
set.seed(521)
stage1 <- c("Control", "Case", "Treated")
stage2 <- c("LumA", "LumB", "HER2", "Basal")
stage3 <- c("CR", "PR", "SD", "PD", "NE")
grid <- expand.grid(stage1 = stage1, stage2 = stage2, stage3 = stage3, stringsAsFactors = FALSE)
base <- stats::rgamma(nrow(grid), shape = 1.4, scale = 8)
base[grid$stage1 == "Case" & grid$stage3 %in% c("PD", "SD")] <-
  base[grid$stage1 == "Case" & grid$stage3 %in% c("PD", "SD")] + stats::rgamma(sum(grid$stage1 == "Case" & grid$stage3 %in% c("PD", "SD")), 2, 6)
base[grid$stage1 == "Treated" & grid$stage3 %in% c("CR", "PR")] <-
  base[grid$stage1 == "Treated" & grid$stage3 %in% c("CR", "PR")] + stats::rgamma(sum(grid$stage1 == "Treated" & grid$stage3 %in% c("CR", "PR")), 2, 6)
grid$value <- round(base, 1)
utils::write.csv(grid, "data.csv", row.names = FALSE)
message("wrote data.csv")
