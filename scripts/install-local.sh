#!/bin/bash
# Install the widget into the current user's KPackage tree using kpackagetool6. Idempotent: upgrades if already installed.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"

KPT="$(command -v kpackagetool6 || true)"
if [[ -z "$KPT" ]]; then
    echo "ERROR: kpackagetool6 not found in PATH."
    echo "       This is a Plasma 6 widget. Please install it on a Plasma 6 system."
    exit 1
fi

ID=$(jq -r '.KPlugin.Id' "$ROOT/package/metadata.json")

if "$KPT" --type Plasma/Applet --list 2>/dev/null | grep -qF "$ID"; then
    "$KPT" --type Plasma/Applet --upgrade "$ROOT/package"
    echo ":: Upgrading $ID"
else
    echo ":: Installing $ID"
    "$KPT" --type Plasma/Applet --install "$ROOT/package"
fi

# Copy icon to the icon theme used by Plasma, respecting XDG_DATA_HOME
ICON_SRC="$ROOT/package/contents/icons/themetoggle.svg"
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
ICON_DST="$DATA_HOME/icons/hicolor/scalable/apps/themetoggle.svg"
mkdir -p "$(dirname "$ICON_DST")"
cp "$ICON_SRC" "$ICON_DST"
echo ":: Icon installed to $ICON_DST"

# Ensure hicolor theme has an index.theme (required for icon discovery)
if [[ ! -f "$DATA_HOME/icons/hicolor/index.theme" ]] && [[ -f /usr/share/icons/hicolor/index.theme ]]; then
    cp /usr/share/icons/hicolor/index.theme "$DATA_HOME/icons/hicolor/index.theme"
fi

# Refresh icon cache so the new icon appears in the widget drawer
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -f "$DATA_HOME/icons/hicolor/" >/dev/null 2>&1 || true
fi
if command -v kbuildsycoca6 >/dev/null 2>&1; then
    kbuildsycoca6 >/dev/null 2>&1 || true
fi

echo
echo "Done. Add the widget via Plasma's Add Widgets dialog (search 'Theme Toggle')."
