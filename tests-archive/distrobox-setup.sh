#!/bin/bash
# One-time setup of a KDE neon distrobox container so we can run
# plasmoidviewer6 (Plasma 6) on any host, even one without Plasma 6.
#
# Distrobox automatically forwards the host's X11/Wayland display and
# mounts $HOME, so the rendered widget appears on the host screen as if
# it were a native window. This is the primary dev loop on this machine.
#
# Idempotent: re-running just makes sure the in-container packages are
# present.
set -euo pipefail

# Pin distrobox to docker by default. Distrobox's auto-detection picks
# podman first if both runtimes are installed; pinning keeps re-clones
# from silently switching backends. Override with
# DBX_CONTAINER_MANAGER=podman if docker isn't your runtime.
export DBX_CONTAINER_MANAGER="${DBX_CONTAINER_MANAGER:-docker}"

NAME="${PLASMOID_TEST_BOX:-plasma6-test}"
IMAGE="${PLASMOID_TEST_IMAGE:-invent-registry.kde.org/neon/docker-images/plasma:unstable}"

# Ensure host prerequisites are present. apt is idempotent, so re-running
# on a fully-provisioned host is a no-op.
ensure_apt_pkg() {
    local bin="$1" pkg="$2"
    if command -v "$bin" >/dev/null; then
        return 0
    fi
    echo ":: Installing missing host dep '$pkg' (provides '$bin')"
    sudo apt-get update -qq
    sudo apt-get install -y --no-install-recommends "$pkg"
}

ensure_apt_pkg distrobox distrobox

# Container runtime: prefer whatever is already installed. Only install
# podman if neither podman nor docker is present — don't add a second
# runtime to a host that already has one.
if ! command -v podman >/dev/null && ! command -v docker >/dev/null; then
    ensure_apt_pkg podman podman
fi

if distrobox list 2>/dev/null | awk '{print $3}' | grep -qx "$NAME"; then
    echo ":: Container '$NAME' already exists"
else
    echo ":: Creating distrobox '$NAME' from $IMAGE"
    distrobox create --name "$NAME" --image "$IMAGE" --yes
fi

# Ensure the container is started. `distrobox create` leaves it in "created"
# state; first `distrobox enter` runs a long init (several minutes) which
# we can't interact with from a script. Start it directly via docker and
# let distrobox-init complete on its own, then use docker exec for our
# apt install — distrobox enter strips newlines from `bash -c` strings
# and evals them through an intermediate shell, which silently breaks
# multi-line commands. docker exec has none of those problems.
docker start "$NAME" >/dev/null 2>&1 || true

echo ":: Waiting for container first-run init to finish (can take several minutes on first run)"
# distrobox-init writes /etc/passwd.done when user-setup is complete. Poll
# for it. On a container that's already been initialised this is instant.
for i in $(seq 1 600); do
    if docker exec "$NAME" test -e /etc/passwd.done 2>/dev/null; then
        break
    fi
    sleep 2
done

if ! docker exec "$NAME" test -e /etc/passwd.done 2>/dev/null; then
    echo "ERROR: container init did not finish within 20 minutes. Check 'docker logs $NAME'."
    exit 1
fi

echo ":: Installing test deps inside '$NAME'"
# plasma-sdk provides plasmoidviewer (the binary is 'plasmoidviewer', not
# 'plasmoidviewer6' on Debian-family — the smoke test handles both names).
# xvfb is a fallback for headless CI; on a real desktop session distrobox
# forwards the host display directly.
docker exec "$NAME" bash -c 'set -e; apt-get update -qq; apt-get install -y --no-install-recommends plasma-sdk jq zip xvfb'

echo
echo "Done. Try a smoke test:"
echo "  ./tests/plasmoidviewer-smoke.sh"
echo
echo "Or open an interactive viewer:"
echo "  DBX_CONTAINER_MANAGER=docker distrobox enter $NAME -- plasmoidviewer -a $(cd "$(dirname "$0")/.." && pwd)/package"
