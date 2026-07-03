#!/bin/bash
# Render the widget for ~3 seconds inside the Plasma 6 distrobox using
# plasmoidviewer6, capture stderr, and fail if any QML import / type
# errors leaked through.
#
# This is a smoke test, not a functional test — it confirms the widget
# loads cleanly under real Plasma 6, which catches the great majority of
# regressions (typos, missing imports, API drift between Plasma minor
# versions). Visual / interaction tests are manual.
set -euo pipefail

# Keep in sync with tests/distrobox-setup.sh — both scripts must agree on
# which backend to talk to, otherwise `distrobox list` won't see the
# container created by setup.
export DBX_CONTAINER_MANAGER=docker

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"

NAME="${PLASMOID_TEST_BOX:-plasma6-test}"

if ! command -v distrobox >/dev/null; then
    echo "ERROR: distrobox not installed. Run ./tests/distrobox-setup.sh first."
    exit 1
fi

if ! distrobox list 2>/dev/null | awk '{print $3}' | grep -qx "$NAME"; then
    echo "ERROR: distrobox '$NAME' does not exist. Run ./tests/distrobox-setup.sh first."
    exit 1
fi

# Build a fresh .plasmoid (catches packaging-time errors too)
"$ROOT/scripts/build-plasmoid.sh"

LOG="$(mktemp -t plasmoid-smoke.XXXXXX)"
trap 'rm -f "$LOG"' EXIT

echo ":: Running plasmoidviewer inside '$NAME' for 3s"

# Run plasmoidviewer for 3s, capture output, check for QML errors.
# Avoid shell variables inside the distrobox bash -c block — distrobox-enter
# runs an intermediate eval that expands them before the container's bash
# sees them, which breaks under set -u. Use `timeout` instead of
# background + kill to sidestep the $PID/$! quoting problem entirely.
distrobox enter "$NAME" -- bash -c "set -e; if command -v plasmoidviewer6 >/dev/null 2>&1; then timeout 3 plasmoidviewer6 -a '$ROOT/package' > /tmp/plasmoid-smoke.out 2>&1 || true; elif command -v plasmoidviewer >/dev/null 2>&1; then timeout 3 plasmoidviewer -a '$ROOT/package' > /tmp/plasmoid-smoke.out 2>&1 || true; else echo 'ERROR: neither plasmoidviewer6 nor plasmoidviewer found inside container. Re-run ./tests/distrobox-setup.sh.' >&2; exit 127; fi; cp /tmp/plasmoid-smoke.out '$LOG'" || true

if [[ ! -s "$LOG" ]]; then
    echo "FAIL: no output captured from plasmoidviewer6"
    exit 1
fi

# Patterns that indicate a real load failure (not just runtime warnings).
# Filter out errors from plasmoidviewer's own desktop containment shell
# (org.kde.desktopcontainment) — those are environment noise, not our widget.
if grep -v 'desktopcontainment' "$LOG" | grep -qiE 'error when loading applet|module ".+" is not installed|cannot assign to non-existent property|is not a type'; then
    echo "FAIL: QML errors detected:"
    echo "─────────────────────────────────────────────"
    grep -iE 'error|warning|not installed|cannot assign' "$LOG" || true
    echo "─────────────────────────────────────────────"
    echo "Full log: $LOG (will be deleted on exit)"
    cat "$LOG"
    exit 1
fi

echo "OK"
