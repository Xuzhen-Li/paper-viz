#!/bin/sh
# Read changed paths from stdin (git diff --name-only). Print what CI should check:
#   ALL  — styles/ or quality-gate tools changed, or too many figure dirs
#   SKIP — no figure dirs to run
#   otherwise one figures/<category>/<slug> path per line
#
# Reuses tools/check_figure.sh / tools/check_all.sh; this only picks targets.
# When GITHUB_OUTPUT is set, also writes mode / need_r / need_py for the workflow.
set -eu

MANY=8
need_full=0
dirs=$(mktemp)
trap 'rm -f "$dirs"' EXIT

while IFS= read -r path || [ -n "${path:-}" ]; do
  path=${path%"$(printf '\r')"}
  case "$path" in
    ""|\#*) continue ;;
  esac
  path=${path#./}

  case "$path" in
    styles|styles/*)
      need_full=1
      ;;
    tools/check_figure.sh|tools/check_all.sh|tools/blocklist.txt)
      need_full=1
      ;;
    figures/*)
      rest=${path#figures/}
      category=${rest%%/*}
      if [ "$category" = "$rest" ] || [ -z "$category" ]; then
        need_full=1
        continue
      fi
      after=${rest#*/}
      slug=${after%%/*}
      if [ -z "$slug" ]; then
        need_full=1
        continue
      fi
      printf '%s\n' "figures/$category/$slug" >> "$dirs"
      ;;
  esac
done

write_output() {
  mode=$1
  need_r=$2
  need_py=$3
  if [ -n "${GITHUB_OUTPUT:-}" ]; then
    {
      printf 'mode=%s\n' "$mode"
      printf 'need_r=%s\n' "$need_r"
      printf 'need_py=%s\n' "$need_py"
    } >> "$GITHUB_OUTPUT"
  fi
}

deps_for_dirs() {
  need_r=false
  need_py=false
  while IFS= read -r dir || [ -n "${dir:-}" ]; do
    [ -z "$dir" ] && continue
    if [ -f "$dir/make_data.py" ] || [ -f "$dir/plot.py" ]; then
      need_py=true
    fi
    if [ -f "$dir/make_data.R" ] || [ -f "$dir/plot.R" ]; then
      need_r=true
    fi
  done
  printf '%s %s\n' "$need_r" "$need_py"
}

if [ "$need_full" -eq 1 ]; then
  write_output all true true
  printf '%s\n' ALL
  exit 0
fi

if [ ! -s "$dirs" ]; then
  write_output skip false false
  printf '%s\n' SKIP
  exit 0
fi

uniq=$(mktemp)
trap 'rm -f "$dirs" "$uniq"' EXIT
sort -u "$dirs" > "$uniq"

kept=$(mktemp)
trap 'rm -f "$dirs" "$uniq" "$kept"' EXIT
while IFS= read -r dir || [ -n "${dir:-}" ]; do
  [ -z "$dir" ] && continue
  [ -d "$dir" ] || continue
  printf '%s\n' "$dir" >> "$kept"
done < "$uniq"

if [ ! -s "$kept" ]; then
  write_output skip false false
  printf '%s\n' SKIP
  exit 0
fi

count=$(wc -l < "$kept")
if [ "$count" -ge "$MANY" ]; then
  write_output all true true
  printf '%s\n' ALL
  exit 0
fi

set -- $(deps_for_dirs < "$kept")
write_output some "$1" "$2"
cat "$kept"
