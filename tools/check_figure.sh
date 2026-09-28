#!/bin/sh
# Run one figure in a temp copy. Exit non-zero on failure.
set -eu
if [ "$#" -ne 1 ]; then
  echo "usage: tools/check_figure.sh <figure_dir>" >&2
  exit 2
fi
ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
FIG=$1
case "$FIG" in
  /*) ;;
  *) FIG=$(CDPATH= cd -- "$FIG" && pwd) ;;
esac
case "$FIG" in
  "$ROOT"/*) ;;
  *) echo "figure dir must live inside the repo" >&2; exit 2 ;;
esac
REL=${FIG#"$ROOT"/}
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/$(dirname "$REL")"
cp -R "$FIG" "$WORK/$REL"
cp -R "$ROOT/styles" "$WORK/styles"
cd "$WORK/$REL"
if [ -z "${R_LIBS_USER:-}" ]; then
  export R_LIBS_USER="$(CDPATH= cd -- "$ROOT/.." && pwd)/.Rlib"
fi


# Blocklist check: scripts/csv + meta fields except `reference` values.
blocklist_check() {
  hit=0
  if grep -RInF -i -f "$ROOT/tools/blocklist.txt" \
      --exclude='*.png' --exclude='*.pdf' --exclude='meta.yaml' .; then
    hit=1
  fi
  if [ -f meta.yaml ]; then
    awk '
      /^[[:space:]]*#/ { print; next }
      /^reference:[[:space:]]*$/ { skip=1; next }
      /^reference:[[:space:]]+.+/ { skip=1; next }
      /^[^[:space:]#]/ { skip=0 }
      skip { next }
      { print }
    ' meta.yaml > "$WORK/_meta_no_reference.yaml"
    if grep -InF -i -f "$ROOT/tools/blocklist.txt" "$WORK/_meta_no_reference.yaml"; then
      hit=1
    fi
  fi
  if [ "$hit" -ne 0 ]; then
    echo "blocklist hit in $REL" >&2
    return 1
  fi
  return 0
}

# lang: drawio has no R/Python scripts. Check the template and preview only.
if [ -f meta.yaml ] && grep -Eq '^lang:[[:space:]]*drawio[[:space:]]*$' meta.yaml; then
  if [ ! -f template.drawio ]; then
    echo "template.drawio missing in $REL" >&2
    exit 1
  fi
  if [ ! -f preview.png ]; then
    echo "preview.png missing in $REL" >&2
    exit 1
  fi
  if grep -RInE --exclude='*.png' --exclude='*.pdf' '(/Users/|/home/|[A-Za-z]:\\)' .; then
    echo "absolute path in $REL" >&2
    exit 1
  fi
  if ! blocklist_check; then
    exit 1
  fi
  echo "ok $REL"
  exit 0
fi

if [ -f make_data.R ]; then
  Rscript make_data.R
elif [ -f make_data.py ]; then
  "${PYTHON:-python3}" make_data.py
else
  echo "no make_data script" >&2
  exit 1
fi

if [ -f plot.R ] && [ -f plot.py ]; then
  "${PYTHON:-python3}" plot.py
fi
if [ -f plot.R ]; then
  Rscript plot.R
elif [ -f plot.py ]; then
  "${PYTHON:-python3}" plot.py
else
  echo "no plot script" >&2
  exit 1
fi

if [ ! -f preview.png ]; then
  echo "preview.png was not written" >&2
  exit 1
fi

if grep -RInE --exclude='*.png' --exclude='*.pdf' '(/Users/|/home/|[A-Za-z]:\\)' .; then
  echo "absolute path in $REL" >&2
  exit 1
fi

if ! blocklist_check; then
  exit 1
fi

echo "ok $REL"
