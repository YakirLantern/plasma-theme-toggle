#!/bin/bash
# Install the widget into the current user's KPackage tree using
# kpackagetool6. Idempotent: upgrades if already installed.
#
# Run on a Plasma 6 system. On a Plasma 5 host this will fail — use the
# distrobox harness in tests/ instead.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"

KPT="$(command -v kpackagetool6 || true)"
if [[ -z "$KPT" ]]; then
    echo "ERROR: kpackagetool6 not found in PATH."
    echo "       This is a Plasma 6 widget. On a host without Plasma 6,"
    echo "       use the distrobox harness instead:"
    echo "         ./tests/distrobox-setup.sh"
    echo "         ./tests/plasmoidviewer-smoke.sh"
    exit 1
fi

ID=$(jq -r '.KPlugin.Id' "$ROOT/package/metadata.json")

if "$KPT" --type Plasma/Applet --list 2>/dev/null | grep -qF "$ID"; then
    echo ":: Upgrading $ID"
    "$KPT" --type Plasma/Applet --upgrade "$ROOT/package"
else
    echo ":: Installing $ID"
    "$KPT" --type Plasma/Applet --install "$ROOT/package"
fi

echo
echo "Done. Add the widget via Plasma's Add Widgets dialog (search 'Theme Toggle')."
