# One whole split into five unequal parts. Run from this directory.
set.seed(7072)
parts <- c("Tumor", "Stroma", "Immune", "Necrosis", "Vessel")
raw <- stats::rexp(length(parts), rate = c(0.7, 1.3, 1.6, 2.8, 3.4))
value <- round(100 * raw / sum(raw), 2)
utils::write.csv(data.frame(part = parts, value = value), "data.csv", row.names = FALSE)
message("wrote data.csv")
