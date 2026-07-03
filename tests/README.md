# Tests

This widget targets **Plasma 6**, but the test harness lives entirely in a distrobox container — so the host distro's Plasma version doesn't matter (it works even from a Plasma 5 host).

## One-time setup

```bash
sudo apt install distrobox podman
./tests/distrobox-setup.sh
```

This pulls the `kdeneon/plasma:user` image (~2 GB), creates a distrobox named `plasma6-test`, and installs `plasma-workspace` + `kpackagetool6` + `jq` + `zip` inside. Distrobox automatically forwards your host's X11/Wayland display and mounts `$HOME`, so anything that runs inside the container draws to your real screen.

## Smoke test (the dev loop)

After every change to the package:

```bash
./tests/plasmoidviewer-smoke.sh
```

This rebuilds the `.plasmoid`, runs `plasmoidviewer6 -a package` inside the container for ~3 seconds, captures stderr, and fails if any QML import / type / property errors leaked through. Catches the great majority of regressions in well under 10 seconds.

## Interactive viewer

For visual inspection (what does it actually look like? does the click action feel right? do the time pickers respond?):

```bash
distrobox enter plasma6-test -- plasmoidviewer6 -a $(pwd)/package
```

Open the config dialog from plasmoidviewer6's window menu to exercise the General / Auto switch / Advanced tabs.

## Multi-Plasma-version matrix (manual, pre-release)

To catch API drift between Plasma minor versions, re-run the smoke test against multiple images by overriding the env vars:

```bash
PLASMOID_TEST_BOX=plasma6-testing  PLASMOID_TEST_IMAGE=docker.io/kdeneon/plasma:testing  ./tests/distrobox-setup.sh
PLASMOID_TEST_BOX=plasma6-testing  ./tests/plasmoidviewer-smoke.sh

PLASMOID_TEST_BOX=plasma6-fedora   PLASMOID_TEST_IMAGE=registry.fedoraproject.org/fedora:41  ./tests/distrobox-setup.sh
PLASMOID_TEST_BOX=plasma6-fedora   ./tests/plasmoidviewer-smoke.sh
```

(The Fedora and openSUSE images need their package install commands adjusted in `distrobox-setup.sh` — the v0.1 setup script only knows apt. That's a deliberate stub for now; generalise it once it's actually needed.)

## Real Plasma session (manual, pre-release)

The smoke test catches load errors but doesn't exercise the *Add Widgets → search → drag onto panel* path, which is the actual user-facing flow. Before each release, install the widget into a real Plasma 6 session:

- **Multipass:** `multipass launch --name plasma6 22.04 && multipass exec plasma6 -- sudo apt install kde-plasma-desktop` then `scp` the `.plasmoid` and use System Settings → Workspace → Plasma Style → Get New… → install from local file.
- **virt-manager:** boot a Fedora KDE Spin or openSUSE Tumbleweed live ISO, install the widget via the same flow.
- **Real second machine:** if you have access to a Plasma 6 machine, that's the most realistic test.

Add the widget to a panel, try every config option, leave it running for an hour with auto-switch enabled across one of the boundary times, suspend and resume the machine across the other boundary.

## What's intentionally not here

- **GitHub Actions / KDE Invent CI.** The local script is enough until the widget has external contributors. When CI is added, `plasmoidviewer-smoke.sh` is the same command — just wrap it in a workflow file.
- **Unit tests for QML logic.** Plasma widgets are too tightly coupled to the runtime to unit-test profitably; the smoke test against real Plasma is the right level.
- **Visual regression tests.** Possible (Xvfb + screenshot diff), but overkill for v0.1.
