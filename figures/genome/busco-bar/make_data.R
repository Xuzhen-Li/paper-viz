# Twelve assemblies scored in the four BUSCO classes. Percents sum to 100.
set.seed(206)

base <- data.frame(
  assembly = sprintf("Asm%02d", 1:12),
  s = c(96.4, 95.1, 93.2, 70.8, 94.0, 88.2, 85.6, 79.4, 76.8, 71.5, 63.2, 57.4),
  d = c(1.8, 2.5, 2.2, 24.6, 1.6, 3.4, 2.9, 12.2, 3.1, 4.2, 5.1, 3.6),
  f = c(0.8, 1.1, 2.1, 2.2, 1.9, 4.0, 5.6, 4.1, 9.2, 11.0, 14.4, 16.2)
)
base$m <- pmax(0.4, 100 - base$s - base$d - base$f)
base$s <- base$s + stats::rnorm(12, 0, 0.25)
base$d <- pmax(0.3, base$d + stats::rnorm(12, 0, 0.15))
base$f <- pmax(0.2, base$f + stats::rnorm(12, 0, 0.15))
base$m <- pmax(0.2, base$m + stats::rnorm(12, 0, 0.15))
tot <- base$s + base$d + base$f + base$m
base$s <- base$s / tot * 100
base$d <- base$d / tot * 100
base$f <- base$f / tot * 100
base$m <- base$m / tot * 100

status <- c(
  "Complete single-copy",
  "Complete duplicated",
  "Fragmented",
  "Missing"
)
df <- rbind(
  data.frame(assembly = base$assembly, status = status[1], percent = round(base$s, 2)),
  data.frame(assembly = base$assembly, status = status[2], percent = round(base$d, 2)),
  data.frame(assembly = base$assembly, status = status[3], percent = round(base$f, 2)),
  data.frame(assembly = base$assembly, status = status[4], percent = round(base$m, 2))
)
utils::write.csv(df, "data.csv", row.names = FALSE)
message("wrote data.csv")
