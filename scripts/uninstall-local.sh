#!/bin/bash
# Remove the widget from the current user's KPackage tree.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"

KPT="$(command -v kpackagetool6 || true)"
[[ -z "$KPT" ]] && { echo "ERROR: kpackagetool6 not found"; exit 1; }

ID=$(jq -r '.KPlugin.Id' "$ROOT/package/metadata.json")

if "$KPT" --type Plasma/Applet --list 2>/dev/null | grep -qF "$ID"; then
    "$KPT" --type Plasma/Applet --remove "$ID"
    echo ":: Removed $ID"
else
    echo ":: $ID is not installed"
fi
