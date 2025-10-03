#!/usr/bin/env bash
set -euo pipefail

GHIDRA_HOME="${GHIDRA_HOME:-/Users/boss_x/Downloads/ghidra_11.0.3_PUBLIC}"
DATASET_ROOT="${DATASET_ROOT:-/Users/boss_x/thesis-dataset-unstripped/dataset_opt0}"

# Export one binary to <binary>.BinExport in the same directory
export_one() {
  local bin="$1"
  local out="${bin}.BinExport"

  # skip if we already exported this file
  if [[ -f "$out" ]]; then
    echo "Skip (exists): $out"
    return
  fi

  echo "Exporting: $bin"
  # unique temporary project directory
  local projdir
  projdir="$(mktemp -d /tmp/gh_proj.XXXXXX)"

  # run Ghidra headless with the BinExport extension
  "$GHIDRA_HOME/support/analyzeHeadless" \
    "$projdir" proj \
    -import "$bin" \
    -analysisTimeoutPerFile 0 \
    -postScript BinExport \
    -deleteProject \
    >"$projdir/log.txt" 2>&1 || {
      echo "Ghidra failed on: $bin"
      echo "See log: $projdir/log.txt"
      return 1
    }

  # If the plugin did not drop the file exactly as <bin>.BinExport, try to locate it
  if [[ ! -f "$out" ]]; then
    # look for any .BinExport with the same basename in the same folder
    local base dir alt
    base="$(basename "$bin")"
    dir="$(dirname "$bin")"
    alt="$(find "$dir" -maxdepth 1 -type f -name "${base}*.BinExport" -print -quit || true)"
    if [[ -n "${alt:-}" && "$alt" != "$out" ]]; then
      mv -f "$alt" "$out"
    fi
  fi

  if [[ -f "$out" ]]; then
    echo "OK: $out"
  else
    echo "Warning: could not find .BinExport for $bin"
    echo "See log: $projdir/log.txt"
  fi

  rm -rf "$projdir" || true
}

export_all() {
  # find all regular files under the dataset that are not already .BinExport
  # you can add more excludes if needed
  find "$DATASET_ROOT" -type f ! -name "*.BinExport" -print0 |
  while IFS= read -r -d '' f; do
    export_one "$f"
  done
}

export_all
echo "Done."

