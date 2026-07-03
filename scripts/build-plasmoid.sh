#!/bin/bash
# Zip the package/ directory into a .plasmoid file ready for
# kpackagetool6 install or KDE Store upload.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"

need() { command -v "$1" >/dev/null || { echo "ERROR: $1 not in PATH"; exit 1; }; }
need jq
need zip

ID=$(jq -r '.KPlugin.Id' "$ROOT/package/metadata.json")
VERSION=$(jq -r '.KPlugin.Version' "$ROOT/package/metadata.json")

OUT_DIR="$ROOT/dist"
OUT="$OUT_DIR/${ID}-${VERSION}.plasmoid"

mkdir -p "$OUT_DIR"
rm -f "$OUT"

( cd "$ROOT/package" && zip -qr "$OUT" . -x '*.swp' -x '*~' -x '.DS_Store' )

echo "Built: $OUT ($(du -h "$OUT" | cut -f1))"
