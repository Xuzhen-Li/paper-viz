# Smoke test for styles/r/theme_house.R. Run from the repo root:
#   Rscript tests/test_theme_house.R
# Checks: theme renders; PNG pixel size = mm / 25.4 * 600; PDF page size = mm / 25.4 * 72;
# PDF text is real text (fonts embedded); grid cells -> mm (43 mm cell, 3 mm gap, 1 mm page
# margin only on 4-cell sides) and off-grid sizes error; only a single 2x2 panel gets +2 pt once;
# mosaic tiles land on the grid; last PNG row is white (ragg and fallback); legacy theme_viz() / pv_palette("categorical") are unchanged.
root <- normalizePath(".")
if (!file.exists(file.path(root, "styles/r/theme_house.R"))) stop("run from the repo root")
source(file.path(root, "styles/r/theme_house.R"))
library(ggplot2)

fail <- 0L
check <- function(ok, msg) {
  cat(if (isTRUE(ok)) "ok  " else "FAIL", msg, "\n")
  if (!isTRUE(ok)) fail <<- fail + 1L
}

png_dims <- function(f) {
  con <- file(f, "rb"); on.exit(close(con))
  hdr <- readBin(con, "raw", 24)
  to_int <- function(b) sum(as.integer(b) * 256^(3:0))
  c(to_int(hdr[17:20]), to_int(hdr[21:24]))
}
pdf_raw <- function(f) {
  r <- readBin(f, "raw", file.info(f)$size)
  rawToChar(r[r != as.raw(0)])
}
has_poppler <- nzchar(Sys.which("pdfinfo")) && nzchar(Sys.which("pdffonts"))
# PDF page size in pt (pdfinfo when present, else the first /MediaBox if it is not compressed).
pdf_box <- function(f) {
  if (has_poppler) {
    line <- grep("^Page size:", system2("pdfinfo", shQuote(f), stdout = TRUE), value = TRUE)
    return(as.numeric(regmatches(line, gregexpr("[0-9.]+", line))[[1]][1:2]))
  }
  txt <- pdf_raw(f)
  m <- regmatches(txt, regexpr("/MediaBox *\\[[^]]*\\]", txt, useBytes = TRUE))
  if (!length(m)) return(NULL)
  as.numeric(strsplit(trimws(gsub("[^0-9. ]", " ", m)), " +")[[1]])[3:4]
}
# TRUE if every font is embedded (text stays text; nothing outlined). NA if it cannot be read.
pdf_fonts_embedded <- function(f) {
  if (has_poppler) {
    out <- system2("pdffonts", shQuote(f), stdout = TRUE)[-(1:2)]
    return(length(out) > 0 && all(grepl(" yes +(yes|no) +(yes|no) +[0-9]+ +[0-9]+ *$", out)))
  }
  txt <- pdf_raw(f)
  if (grepl("/FontFile", txt, useBytes = TRUE)) TRUE else NA
}

# legacy interfaces --------------------------------------------------------
chip <- c("#134aa3", "#f6a3b1", "#0b5475", "#dc1f26", "#835ca6", "#f7922c", "#fbee61", "#981b1e")
check(identical(pv_palette(), chip), "pv_palette() default is the chip eight")
check(identical(pv_palette("categorical", 3), chip[1:3]), "pv_palette('categorical', 3)")
check(length(pv_palette("categorical", 10)) == 10, "pv_palette('categorical', 10) still ramps")
check(identical(pv_palette("sequential"), c("#F7FBFF", "#C6DBEF", "#6BAED6", "#2171B5", "#08306B")),
      "pv_palette('sequential') unchanged")
check(inherits(theme_viz(), "theme"), "theme_viz() still returns a theme")
check(is.function(pv_save), "pv_save() still available")

# house palettes -------------------------------------------------------------
check(identical(unname(pv_palette("house", 3)), c("#1F72AE", "#F77E12", "#119B76")), "pv_palette('house', 3)")
check(length(pv_palette("house_div")) == 9 && pv_palette("house_div")[5] == "#F7F7F7", "house_div centre #F7F7F7")
check(identical(unname(pv_palette("ssp")["SSP5-8.5"]), "#9C2125"), "ssp named colours")
check(inherits(try(pv_palette("house", 10), silent = TRUE), "try-error"), "house refuses > 9 colours")

# theme -----------------------------------------------------------------------
th <- theme_house()
check(th$axis.text$size == 7 && th$axis.title$size == 8 && th$plot.tag$size == 10, "theme_house sizes 7/8/10")
check(th$plot.tag$face == "bold" && th$axis.title$face == "plain", "tag bold, axis title plain")
check(abs(th$panel.border$linewidth * .pt * 72 / 96 - 0.5) < 1e-9, "frame 0.5 pt")
check(inherits(th$panel.grid, "element_blank"), "no grid")

set.seed(1)
d <- data.frame(x = rnorm(40), y = rnorm(40), g = rep(c("A", "B"), 20))
p <- ggplot(d, aes(x, y, fill = g)) +
  geom_point(shape = 21, size = 2.3, stroke = 0.3) +
  geom_line(aes(colour = g), linewidth = pv_house_lw("main")) +
  annotate("text", x = 0, y = 2, label = "label 7 pt", size = pv_pt2size(7)) +
  scale_fill_manual(values = unname(pv_palette("house", 2))) +
  scale_colour_manual(values = unname(pv_palette("house", 2))) +
  labs(x = "Value x (unit)", y = "Value y (unit)") +
  theme_house()

out <- file.path(tempdir(), "house-test")
dir.create(out, showWarnings = FALSE)
check(pv_fmt_p(0.0123) == "italic(P)*' = 0.012'" && pv_fmt_p(2e-5) == "italic(P)*' < 0.001'" &&
        grepl("10'^'\u22125'", pv_fmt_p(2e-5, exact = TRUE), fixed = TRUE), "pv_fmt_p: P < 0.001 by default, exponent only if exact")

# grid conversion -------------------------------------------------------------------
check(identical(pv_grid_span(1:4), c(43, 89, 135, 181)), "span: 43 / 89 / 135 / 181 mm")
check(identical(pv_grid_canvas(1:4), c(43, 89, 135, 183)), "canvas: 43 / 89 / 135 / 183 mm (4 cells + 1 mm margins)")
check(identical(pv_house_cells("2x1"), c(2L, 1L)) && identical(pv_house_cells(c(3, 4)), c(3L, 4L)) &&
        identical(pv_house_cells(" 4 X 2 "), c(4L, 2L)) && identical(pv_house_cells("1\u00d71"), c(1L, 1L)),
      "cells parse: \"2x1\", c(3, 4), \" 4 X 2 \", \"1\u00d71\"")
g41 <- pv_house_canvas("4x1"); g22 <- pv_house_canvas(c(2, 2)); g44 <- pv_house_canvas(c(4, 4))
check(g41$width_mm == 183 && g41$height_mm == 43 && g41$content_width_mm == 181 && g41$margin_x_mm == 1 &&
        g41$margin_y_mm == 0, "4x1: canvas 183 x 43, content 181 wide, 1 mm side margins only")
check(g22$width_mm == 89 && g22$height_mm == 89 && g22$margin_x_mm == 0, "2x2: 89 x 89, no margin")
check(g44$width_mm == 183 && g44$height_mm == 183 && g44$margin_y_mm == 1, "4x4: 183 x 183, margins on both axes")
# tiles of a 4-cell row with 3 mm gaps rebuild the 183 mm page exactly
for (row in list(c(1, 1, 1, 1), c(1, 1, 2), c(2, 2), c(1, 3), 4)) {
  check(abs(2 * HOUSE_PAGE_MARGIN_MM + sum(pv_grid_span(row)) + HOUSE_GAP_MM * (length(row) - 1) - 183) < 1e-9,
        sprintf("row %s + gaps + margins = 183 mm", paste(row, collapse = "+")))
}
errs <- function(expr) inherits(try(expr, silent = TRUE), "try-error")
check(errs(pv_house_cells(c(5, 1))) && errs(pv_house_cells(c(0, 1))) && errs(pv_house_cells(c(1.5, 1))) &&
        errs(pv_house_cells("2x")) && errs(pv_house_cells(c(1, 2, 3))) && errs(pv_house_cells("5x1")),
      "off-grid cells error (5, 0, 1.5, \"2x\", length 3, \"5x1\")")
err_msg <- function(expr) tryCatch({ expr; "" }, error = function(e) conditionMessage(e))
check(all(vapply(list(c(NaN, 1), c(Inf, 1), c(1, -Inf), c(NA, 1)), function(v)
        grepl("off the house grid", err_msg(pv_house_cells(v))), logical(1))),
      "non-finite cells (NaN, Inf, -Inf, NA) error with the grid message")
check(all(vapply(list(NaN, Inf, -Inf, NA_real_), function(v)
        grepl("not a finite size in mm", err_msg(.pv_mm_to_cells(v, "width"))), logical(1))) &&
        grepl("not a finite size", err_msg(pv_save_house(p, file.path(out, "bad"), "single", NaN, preview = FALSE))) &&
        grepl("not a finite size", err_msg(pv_save_house(p, file.path(out, "bad"), Inf, 43, preview = FALSE))),
      "non-finite width / height_mm error: not a finite size (no 'nearest grid size')")
check(errs(pv_save_house(p, file.path(out, "bad"), "single", 76, preview = FALSE)) &&
        errs(pv_save_house(p, file.path(out, "bad"), 120, 43, preview = FALSE)) &&
        errs(pv_save_house(p, file.path(out, "bad"), width = 181, height_mm = 43, preview = FALSE)) &&
        errs(pv_save_house(p, file.path(out, "bad"), cells = "2x1", width = "single", preview = FALSE)),
      "off-grid explicit mm (89 x 76, 120 mm, 181 mm) and cells + width together error")
check(identical(pv_save_house(p, file.path(out, "mm"), 135, 89, preview = FALSE)$cells, c(3L, 2L)) &&
        identical(pv_save_house(p, file.path(out, "mm"), "double", preview = FALSE)$cells, c(4L, 1L)),
      "grid mm and presets convert: 135 x 89 -> 3x2, \"double\" -> 4x1")

for (case in list(list("2x2", 89, 89, 2), list(c(4, 1), 183, 43, 0), list("1x1", 43, 43, 0), list("2x1", 89, 43, 0))) {
  w <- paste(pv_house_cells(case[[1]]), collapse = "x"); mm_w <- case[[2]]; mm_h <- case[[3]]; want_bump <- case[[4]]
  res <- pv_save_house(p, file.path(out, w), cells = case[[1]], preview = TRUE)
  check(res$bump == want_bump, sprintf("%s: bump = %s pt", w, want_bump))
  dims <- png_dims(res$png)
  want <- round(c(mm_w, mm_h) / 25.4 * 600)
  check(all(abs(dims - want) <= 1), sprintf("%s: PNG %dx%d px (want %dx%d at 600 dpi)", w, dims[1], dims[2], want[1], want[2]))
  box <- pdf_box(res$pdf)
  wantpt <- c(mm_w, mm_h) / 25.4 * 72
  if (is.null(box)) {
    cat("skip", w, ": PDF page size (no pdfinfo; MediaBox compressed)\n")
  } else {
    check(all(abs(box - wantpt) < 1), sprintf("%s: PDF %.1fx%.1f pt (want %.1fx%.1f)", w, box[1], box[2], wantpt[1], wantpt[2]))
  }
  emb <- pdf_fonts_embedded(res$pdf)
  if (is.na(emb)) cat("skip", w, ": PDF font check (no pdffonts)\n") else
    check(emb, sprintf("%s: PDF fonts embedded as text (not outlined)", w))
  check(png_dims(file.path(out, "preview.png"))[1] == 1200, sprintf("%s: preview.png 1200 px wide", w))
}
# no double bump; input plot untouched
p9 <- p + theme_house(base_size = 9)
check(pv_save_house(p9, file.path(out, "s9"), cells = c(2, 2), preview = FALSE)$bump == 0, "base_size 9 not bumped again")
bp <- pv_bump_text(p, 2)
check(bp$theme$axis.text$size == 9 && bp$theme$axis.title$size == 10, "bump: ticks 9, axis titles 10")
check(abs(bp$layers[[3]]$aes_params$size - pv_pt2size(9)) < 1e-9, "bump: annotate text 7 -> 9 pt")
check(abs(p$layers[[3]]$aes_params$size - pv_pt2size(7)) < 1e-9, "bump leaves the input plot unchanged")
check(pv_save_house(p + facet_wrap(~g), file.path(out, "facet"), cells = c(2, 2), preview = FALSE)$bump == 0,
      "faceted plot at 2x2 is not bumped")
check(pv_save_house(p, file.path(out, "s89"), "single", 89, preview = FALSE)$bump == 2,
      "old call width = \"single\", height_mm = 89 is 2x2 and bumped")
check(pv_save_house(p, file.path(out, "s21"), "single", 43, preview = FALSE)$bump == 0 &&
        pv_save_house(p, file.path(out, "s12"), cells = c(1, 2), preview = FALSE)$bump == 0 &&
        pv_save_house(p, file.path(out, "s33"), cells = c(3, 3), preview = FALSE)$bump == 0,
      "single panel at 2x1, 1x2, 3x3 is not bumped (only 2x2 is)")

# default in-plot text size: 7 pt, +2 pt for a single 2x2 panel ---------------------------
check(abs(GeomText$default_aes$size - 7 / .pt) < 1e-9 && abs(GeomLabel$default_aes$size - 7 / .pt) < 1e-9,
      "geom_text / geom_label default size 7 pt after sourcing theme_house.R")
pdft <- ggplot(d, aes(x, y)) + geom_text(aes(label = g)) + annotate("text", x = 0, y = 0, label = "n") + theme_house()
bd <- pv_bump_text(pdft, 2)
check(all(vapply(bd$layers, function(l) abs(l$aes_params$size - 9 / .pt) < 1e-9, logical(1))),
      "bump: default-size text layers 7 -> 9 pt")
check(all(vapply(pdft$layers, function(l) is.null(l$aes_params$size) || abs(l$aes_params$size - 7 / .pt) < 1e-9, logical(1))),
      "bump leaves default-size layers of the input plot unchanged")
if (requireNamespace("patchwork", quietly = TRUE)) {
  check(pv_save_house(patchwork::wrap_plots(pdft), file.path(out, "pw1"), cells = c(2, 2), preview = FALSE)$bump == 0,
        "patchwork with a single subplot is not bumped")
}

# in-plot text uses the theme font (no device-default NimbusSans etc.) ----------------
if (has_poppler) {
  fonts_of <- function(f) {
    out <- system2("pdffonts", shQuote(f), stdout = TRUE)[-(1:2)]
    sub("^[A-Z]{6}\\+", "", vapply(strsplit(trimws(out), " +"), `[`, "", 1))
  }
  pt <- ggplot(d, aes(x, y)) + geom_point() + geom_text(aes(label = g)) +
    geom_label(data = d[1:2, ], aes(label = g)) +
    annotate("text", x = 0, y = 0, label = "note") + theme_house()
  # also prove the save-time patch works without the geom defaults set at source time
  old <- list(text = GeomText$default_aes$family, label = GeomLabel$default_aes$family)
  update_geom_defaults("text", list(family = "")); update_geom_defaults("label", list(family = ""))
  res <- pv_save_house(pt, file.path(out, "fonts"), cells = c(4, 1), preview = FALSE)
  pw <- if (requireNamespace("patchwork", quietly = TRUE)) patchwork::wrap_plots(pt, pt) else pt
  res2 <- pv_save_house(pw, file.path(out, "fonts_pw"), cells = c(4, 1), preview = FALSE)
  res_m <- pv_save_house(pv_house_mosaic(list(list(plot = pt, at = c(1, 1), cells = c(1, 1)),
                                              list(plot = pw, at = c(2, 1), cells = c(3, 1))), c(4, 1)),
                         file.path(out, "fonts_mosaic"), cells = c(4, 1), preview = FALSE)
  pv_house_geom_defaults()
  for (f in c(res$pdf, res2$pdf, res_m$pdf)) {
    fs <- fonts_of(f)
    check(length(fs) > 0 && !any(grepl("Nimbus", fs)) && length(unique(substr(gsub("[^A-Za-z]", "", fs), 1, 5))) == 1,
          sprintf("%s: one font family in PDF (%s)", basename(f), paste(unique(fs), collapse = ", ")))
  }
} else cat("skip font-family check (no pdffonts)\n")

# point size: demo A values, physical size shared with Python house.POINT -------------
pd <- pv_point_dims()
check(abs(pd[["outer_mm"]] - 2.04) < 0.02 && abs(pd[["outline_pt"]] - 0.425) < 0.005,
      sprintf("HOUSE_POINT: outer %.2f mm, outline %.3f pt", pd[["outer_mm"]], pd[["outline_pt"]]))

# PNG fallback without ragg (CI has no ragg): pixel size must follow mm and dpi -------
png_px <- function(f) {
  con <- file(f, "rb"); on.exit(close(con))
  h <- readBin(con, "raw", 24)
  c(sum(as.integer(h[17:20]) * 256^(3:0)), sum(as.integer(h[21:24]) * 256^(3:0)))
}
requireNamespace <- function(package, ...) if (identical(package, "ragg")) FALSE else
  base::requireNamespace(package, ...)
td3 <- tempfile("noragg"); dir.create(td3)
res3 <- pv_save_house(ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point() +
                        ggplot2::annotate("text", 3, 30, label = "x") + theme_house(),
                      file.path(td3, "figure"), cells = "2x1", dpi = 300)
rm(requireNamespace)
px <- png_px(res3$png); pv <- png_px(file.path(td3, "preview.png"))
check(abs(px[1] - round(89 / 25.4 * 300)) <= 1 && abs(px[2] - round(43 / 25.4 * 300)) <= 1 && pv[1] == 1200,
      sprintf("no-ragg PNG fallback: figure %dx%d px, preview %d px wide", px[1], px[2], pv[1]))

# Bottom edge: x-axis title descenders (g, y, parentheses) must not touch the last pixel row ---
# ragg / cairo-png lay text out with slightly different metrics than cairo PDF, so the PNG needs
# real bottom headroom (theme_house plot.margin bottom). Checked on the ragg and fallback paths.
if (requireNamespace("png", quietly = TRUE)) {
  desc_plot <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point() +
    ggplot2::labs(x = "Berry weight (g, log scale)", y = "Yield (kg)") + theme_house()
  last_row_white <- function(f) {
    a <- png::readPNG(f)
    last <- a[dim(a)[1], , 1:3, drop = FALSE]
    all(last > 0.98)
  }
  paths <- list(ragg = requireNamespace("ragg", quietly = TRUE), fallback = TRUE)
  for (path in names(paths)) {
    if (!paths[[path]]) { cat("skip bottom-edge check on", path, "(ragg not installed)\n"); next }
    if (path == "fallback")
      requireNamespace <- function(package, ...) if (identical(package, "ragg")) FALSE else
        base::requireNamespace(package, ...)
    tdb <- tempfile(paste0("bottom-", path)); dir.create(tdb)
    for (cl in c("1x1", "2x1", "2x2", "4x1")) {
      rb <- pv_save_house(desc_plot, file.path(tdb, paste0("figure", cl)), cells = cl, preview = FALSE)
      check(last_row_white(rb$png), sprintf("%s PNG %s cells (%g x %g mm): last pixel row is white",
                                            path, cl, rb$width_mm, rb$height_mm))
    }
    if (exists("requireNamespace", envir = globalenv(), inherits = FALSE)) rm(requireNamespace)
  }
} else cat("skip bottom-edge check (png package not installed)\n")

# mosaic: tiles sit at 1 + 46 * (k - 1) mm on the 183 mm canvas ---------------------------
if (requireNamespace("png", quietly = TRUE)) {
  # solid-filled tiles, no theme margins, so the ink box of each tile = its grid box
  solid <- function(col) ggplot2::ggplot() + ggplot2::theme_void() +
    ggplot2::theme(plot.background = ggplot2::element_rect(fill = col, colour = NA),
                   plot.margin = ggplot2::margin(0, 0, 0, 0))
  mo <- pv_house_mosaic(list(list(plot = solid("#FF0000"), at = c(1, 1), cells = c(1, 1)),
                             list(plot = solid("#00FF00"), at = c(2, 1), cells = c(2, 1)),
                             list(plot = solid("#0000FF"), at = c(4, 1), cells = c(1, 2)),
                             list(plot = solid("#000000"), at = c(1, 2), cells = c(3, 1))), c(4, 2))
  tdm <- tempfile("mosaic"); dir.create(tdm)
  rm_ <- pv_save_house(mo, file.path(tdm, "figure"), cells = c(4, 2), dpi = 254, preview = FALSE)  # 10 px/mm
  a <- png::readPNG(rm_$png)
  ink_x <- function(rgb, row_mm) {
    r <- a[round(row_mm * 10), , 1:3]
    hit <- which(abs(r[, 1] - rgb[1]) < 0.05 & abs(r[, 2] - rgb[2]) < 0.05 & abs(r[, 3] - rgb[3]) < 0.05)
    c(min(hit) - 1, max(hit)) / 10
  }
  near <- function(got, want) all(abs(got - want) <= 0.15)
  check(rm_$width_mm == 183 && rm_$height_mm == 89, "mosaic 4x2 canvas 183 x 89 mm")
  check(near(ink_x(c(1, 0, 0), 20), c(1, 44)) && near(ink_x(c(0, 1, 0), 20), c(47, 136)) &&
          near(ink_x(c(0, 0, 1), 20), c(139, 182)) && near(ink_x(c(0, 0, 0), 70), c(1, 136)) &&
          near(ink_x(c(0, 0, 1), 70), c(139, 182)),
        "mosaic tiles at x = 1, 47, 139 mm; 3 mm gaps; right edge 182 mm (= 183 - 1)")
  col_red <- which(abs(a[, 200, 1] - 1) < 0.05 & a[, 200, 2] < 0.05)
  col_blk <- which(rowSums(a[, 200, 1:3]) < 0.15)
  check(near(c(min(col_red) - 1, max(col_red)) / 10, c(0, 43)) &&
          near(c(min(col_blk) - 1, max(col_blk)) / 10, c(46, 89)),
        "mosaic rows: y = 0-43 and 46-89 mm (no vertical margin at 2 cells high)")
  check(errs(pv_house_mosaic(list(list(plot = solid("red"), at = c(4, 1), cells = c(2, 1))), c(4, 1))) &&
          errs(pv_house_mosaic(list(list(plot = solid("red"), at = c(1, 1), cells = c(2, 1)),
                                    list(plot = solid("red"), at = c(2, 1), cells = c(1, 1))), c(4, 1))) &&
          errs(pv_save_house(mo, file.path(tdm, "x"), cells = c(4, 1), preview = FALSE)),
        "mosaic: out-of-page tile, overlapping tiles, and wrong save size error")
} else cat("skip mosaic pixel check (png package not installed)\n")

if (fail) { cat(fail, "check(s) failed\n"); quit(status = 1) }
cat("all R house-theme checks passed\n")
