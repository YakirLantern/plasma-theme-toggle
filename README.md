# Theme Toggle — one-click theme switching for KDE Plasma 6

A panel widget that flips between any two Global Themes — one light, one dark — with a single click, and optionally on a time-of-day schedule.

**Status:** v0.1 in development. Not yet on the KDE Store.

## Why, when Plasma 6.5+ switches themes by itself?

Plasma 6.5 added built-in scheduled day/night Global Theme switching, and if a schedule is all you want, use that. This widget covers what the built-in doesn't:

- **A one-click toggle that lives in your panel.** Instant manual switching with a visible indicator of the current state — no trip through System Settings.
- **Per-component switching** *(roadmap — the v0.2 headline)*: applying a full Global Theme resets more than most people expect. The Advanced tab will let you switch only the components you pick — say, Color Scheme + Icon Theme + Wallpaper — while leaving your Plasma Style, panel setup, and window decorations untouched.
- **Plasma 6.0–6.4 support.** Distros like Debian 13 ship pre-6.5 Plasma with no built-in scheduler; the widget's own fixed-time schedule fills that gap.

## What it does

- Click the panel icon to flip between a configured *light* and *dark* Global Theme (Look-and-Feel package) — any installed themes, not just Breeze.
- Optionally schedule the switch by time of day — the widget applies the right theme on every 30s tick, automatically catching up after suspend or missed ticks.
- Configurable click action (toggle / show menu / cycle), icon style (follow scheme / sun-moon / yin-yang), and notification on switch.

## Repository layout

```
plasma-theme-toggle/
├── README.md                   # this file
├── LICENSE                     # GPL-3.0
├── docs/DESIGN.md              # design notes — config tabs, schedule logic, testing
├── docs/ROADMAP.md             # release plan
├── package/                    # the directory that becomes the .plasmoid zip
│   ├── metadata.json
│   └── contents/
│       ├── config/
│       │   ├── main.xml        # KConfigXT — all settings
│       │   └── config.qml      # ConfigModel with 3 tabs
│       ├── ui/
│       │   ├── main.qml        # the widget itself
│       │   ├── configGeneral.qml
│       │   ├── configAutoSwitch.qml
│       │   └── configAdvanced.qml
│       └── icons/themetoggle.svg
├── scripts/
│   ├── build-plasmoid.sh       # zip package/ → dist/*.plasmoid
│   ├── install-local.sh        # kpackagetool6 install/upgrade
│   └── uninstall-local.sh
└── tests/
    ├── README.md               # detailed test docs
    ├── distrobox-setup.sh      # one-time KDE neon container creation
    └── plasmoidviewer-smoke.sh # render under Plasma 6, fail on QML errors
```

## Dev workflow

Your host doesn't need Plasma 6 — all rendering happens inside a distrobox container running KDE neon (latest Plasma 6), with the host's display forwarded:

```bash
# One-time
./tests/distrobox-setup.sh

# After every change
./tests/plasmoidviewer-smoke.sh

# For visual inspection
distrobox enter plasma6-test -- plasmoidviewer -a $(pwd)/package
```

See [`tests/README.md`](tests/README.md) for the multi-image matrix and pre-release manual checks.

## Installing on a Plasma 6 system

```bash
./scripts/install-local.sh
```

Then add the widget via Plasma's *Add Widgets* dialog (search "Theme Toggle"). To remove:

```bash
./scripts/uninstall-local.sh
```

## License

[GPL-3.0-or-later](LICENSE).

## Releasing

Manual for now. Before each release:

1. Bump `KPlugin.Version` in `package/metadata.json`.
2. Update `CHANGELOG.md` (TBD).
3. `./scripts/build-plasmoid.sh` to produce `dist/io.github.yakirlantern.themetoggle-X.Y.Z.plasmoid`.
4. Run the smoke test against the latest stable + testing KDE neon images.
5. Manually test installing into a real Plasma 6 session via `kpackagetool6 --install`.
6. Upload to [store.kde.org](https://store.kde.org) under *Plasma 6 Add-Ons → Plasmoids*. At least one screenshot is required by the store.
