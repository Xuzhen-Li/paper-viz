#!/bin/sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
fail=0
found=0
for dir in "$ROOT"/figures/*/*; do
  [ -d "$dir" ] || continue
  [ -f "$dir/meta.yaml" ] || continue
  found=1
  if ! "$ROOT/tools/check_figure.sh" "$dir"; then
    fail=1
  fi
done
if [ "$found" -eq 0 ]; then
  echo "no figures" >&2
  exit 1
fi
exit "$fail"
