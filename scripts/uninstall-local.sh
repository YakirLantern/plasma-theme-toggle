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

# Remove icon from the icon theme used by Plasma, respecting XDG_DATA_HOME
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
ICON_DST="$DATA_HOME/icons/hicolor/scalable/apps/themetoggle.svg"
if [[ -f "$ICON_DST" ]]; then
    rm "$ICON_DST"
    echo ":: Icon removed from $ICON_DST"
fi
