#!/bin/sh
# Preview PNG size checks shared by tools/check_figure.sh (sourced) and the unit tests (CLI).
#
#   sh tools/check_png_grid.sh <preview.png> [meta.yaml]
#
# Figures whose meta.yaml has `cells: WxH` (house grid) must match the grid canvas:
# a side of 1 / 2 / 3 / 4 cells is 43 / 89 / 135 / 183 mm. pv_save_house() / save_house() write
# preview.png 1200 px wide, i.e. at dpi = 1200 / (width mm / 25.4). Expected px per side =
# round(mm / 25.4 * dpi), +-1 px. The pHYs chunk must agree with that dpi to +-1 dpi: grDevices
# png() (no ragg) stores an integer dpi, so pHYs alone is too coarse for a +-1 px check, but it
# still catches a preview drawn on the wrong physical canvas. No pHYs -> error.
# Figures without `cells` only need each side >= PV_MIN_PNG_PX (default 300) px.
# POSIX sh + od + awk only.

PREVIEW_WIDTH_PX=${PV_PREVIEW_WIDTH_PX:-1200}
MIN_PNG_PX=${PV_MIN_PNG_PX:-300}

# png_label <png>: name used in messages ($REL is set by check_figure.sh).
png_label() {
  if [ -n "${REL:-}" ]; then printf '%s/%s\n' "$REL" "$(basename "$1")"; else printf '%s\n' "$1"; fi
}

# png_ihdr <png>: print "width height" from the IHDR header, or fail.
png_ihdr() {
  sig=$(od -An -tx1 -N8 "$1" | tr -d ' \n')
  ihdr=$(od -An -c -j12 -N4 "$1" | tr -d ' \n')
  if [ "$sig" != "89504e470d0a1a0a" ] || [ "$ihdr" != "IHDR" ]; then
    echo "$(png_label "$1") is not a valid PNG" >&2
    return 1
  fi
  label=$(png_label "$1")
  # shellcheck disable=SC2046 # split the 8 header bytes on purpose
  set -- $(od -An -tu1 -j16 -N8 "$1")
  if [ "$#" -ne 8 ]; then
    echo "$label has a truncated PNG header" >&2
    return 1
  fi
  echo "$(( ($1 << 24) + ($2 << 16) + ($3 << 8) + $4 )) $(( ($5 << 24) + ($6 << 16) + ($7 << 8) + $8 ))"
}

# png_dpi <png>: print dpi from the pHYs chunk (unit = metre, x = y), or "none".
png_dpi() {
  od -An -tu1 -v "$1" 2>/dev/null | awk '
    BEGIN { n = 0; p = 8; done = 0 }
    {
      for (i = 1; i <= NF; i++) b[n++] = $i + 0
      while (!done && p + 8 <= n) {
        len = b[p] * 16777216 + b[p + 1] * 65536 + b[p + 2] * 256 + b[p + 3]
        t = sprintf("%c%c%c%c", b[p + 4], b[p + 5], b[p + 6], b[p + 7])
        if (t == "pHYs") {
          if (p + 17 > n) break
          x = b[p + 8] * 16777216 + b[p + 9] * 65536 + b[p + 10] * 256 + b[p + 11]
          y = b[p + 12] * 16777216 + b[p + 13] * 65536 + b[p + 14] * 256 + b[p + 15]
          u = b[p + 16]
          if (u == 1 && x > 0 && x == y) printf "%.6f\n", x * 0.0254
          else print "none"
          done = 1
        } else if (t == "IDAT" || t == "IEND") {
          print "none"
          done = 1
        } else {
          p += 12 + len
        }
      }
      if (done) exit
    }
    END { if (!done) print "none" }'
}

# meta_cells <meta.yaml>: print the raw `cells:` value (empty if none).
meta_cells() {
  [ -f "$1" ] || return 0
  sed -nE 's/^cells:[[:space:]]*(.*[^[:space:]])[[:space:]]*$/\1/p' "$1" | head -n 1 |
    sed -E "s/^[\"']//; s/[\"']$//"
}

# check_png_size <png>: fixed floor for figures without cells.
check_png_size() {
  dims=$(png_ihdr "$1") || return 1
  # shellcheck disable=SC2086 # "w h" -> two words
  set -- "$1" $dims
  if [ "$2" -lt "$MIN_PNG_PX" ] || [ "$3" -lt "$MIN_PNG_PX" ]; then
    echo "$(png_label "$1") is ${2}x${3} px; each side must be at least ${MIN_PNG_PX} px (degenerate render?)" >&2
    return 1
  fi
}

# check_png_grid <png> <cells>: exact house-grid canvas size.
check_png_grid() {
  png=$1
  cells=$2
  label=$(png_label "$png")
  case "$cells" in
    \[*\]) cells=$(printf '%s' "$cells" | tr -d '[] ' | tr ',' 'x') ;;
  esac
  cw=$(printf '%s' "$cells" | sed -nE 's/^[[:space:]]*([0-9]+)[[:space:]]*(x|X|×)[[:space:]]*([0-9]+)[[:space:]]*$/\1/p')
  ch=$(printf '%s' "$cells" | sed -nE 's/^[[:space:]]*([0-9]+)[[:space:]]*(x|X|×)[[:space:]]*([0-9]+)[[:space:]]*$/\3/p')
  if [ -z "$cw" ] || [ -z "$ch" ]; then
    echo "$label: meta.yaml cells: '$2' is not WxH (e.g. 2x1)" >&2
    return 1
  fi
  for c in "$cw" "$ch"; do
    if [ "$c" -lt 1 ] || [ "$c" -gt 4 ]; then
      echo "$label: meta.yaml cells: $2 is off the house grid; each side must be 1-4 cells" >&2
      return 1
    fi
  done
  dims=$(png_ihdr "$png") || return 1
  dpi=$(png_dpi "$png")
  if [ "$dpi" = "none" ] || [ -z "$dpi" ]; then
    echo "$label: cannot read dpi (no usable pHYs chunk); cells figures must be saved with pv_save_house() / save_house()" >&2
    return 1
  fi
  echo "$cw $ch $dims $dpi $PREVIEW_WIDTH_PX" | awk -v label="$label" '
    function side(n) { return n == 1 ? 43 : n == 2 ? 89 : n == 3 ? 135 : 183 }
    {
      cw = $1; ch = $2; w = $3; h = $4; phys = $5; pw = $6
      dpi = pw / (side(cw) / 25.4)
      ew = int(side(cw) / 25.4 * dpi + 0.5); eh = int(side(ch) / 25.4 * dpi + 0.5)
      if (w - ew > 1 || ew - w > 1 || h - eh > 1 || eh - h > 1) {
        printf "%s: cells %dx%d needs %d x %d mm = %d x %d px (preview %d px wide, %.2f dpi; +-1 px); got %d x %d px = %.1f x %.1f mm\n",
          label, cw, ch, side(cw), side(ch), ew, eh, pw, dpi, w, h, w / dpi * 25.4, h / dpi * 25.4 > "/dev/stderr"
        exit 1
      }
      if (phys - dpi > 1.05 || dpi - phys > 1.05) {
        printf "%s: cells %dx%d: PNG pHYs says %.2f dpi, so the %d px canvas is %.1f x %.1f mm, not %d x %d mm (want %.2f dpi +-1)\n",
          label, cw, ch, phys, w, w / phys * 25.4, h / phys * 25.4, side(cw), side(ch), dpi > "/dev/stderr"
        exit 1
      }
    }'
}

# check_preview_size <png> <meta.yaml>: grid check when meta has cells, else the px floor.
check_preview_size() {
  cells=$(meta_cells "$2")
  if [ -n "$cells" ]; then
    check_png_grid "$1" "$cells"
  else
    check_png_size "$1"
  fi
}

# CLI (skipped when sourced with PV_PNG_LIB_ONLY=1).
if [ "${PV_PNG_LIB_ONLY:-}" != 1 ]; then
  if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    echo "usage: tools/check_png_grid.sh <preview.png> [meta.yaml]" >&2
    exit 2
  fi
  check_preview_size "$1" "${2:-}"
fi
