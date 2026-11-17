# Theme Toggle — one-click theme switching for KDE Plasma 6

A panel widget that flips between any two Global Themes — one light, one dark — with a single click, and optionally on a time-of-day schedule.

**Status:** v1.0.0 — first public release on KDE Store.

## What it does

- Click the panel icon to flip between a configured *light* and *dark* Global Theme (Look-and-Feel package) — any installed themes, not just Breeze.
- Optionally schedule the switch by time of day — the widget applies the right theme on every 30s tick, automatically catching up after suspend or missed ticks.
- Configurable click action (toggle / show menu / cycle), icon style (yin-yang / sun-moon), and notification on switch.

## Repository layout

```
plasma-theme-toggle/
├── README.md                   # this file
├── LICENSE                     # GPL-3.0
├── CHANGELOG.md                # release history
├── package/                    # the directory that becomes the .plasmoid zip
│   ├── metadata.json
│   └── contents/
│       ├── config/
│       │   ├── main.xml        # KConfigXT — all settings
│       │   └── config.qml      # ConfigModel with 2 tabs (General + Auto switch)
│       ├── ui/
│       │   ├── main.qml        # the widget itself
│       │   ├── configGeneral.qml
│       │   └── configAutoSwitch.qml
│       └── icons/themetoggle.svg
├── scripts/
│   ├── build-plasmoid.sh       # zip package/ → dist/*.plasmoid
│   ├── install-local.sh        # kpackagetool6 install/upgrade
│   └── uninstall-local.sh
```

## Installation

```bash
./scripts/install-local.sh
```

Then add the widget via Plasma's *Add Widgets* dialog (search "Theme Toggle"). To remove:

```bash
./scripts/uninstall-local.sh
```

## How it works

- The widget uses `plasma-apply-lookandfeel --apply <id>` to switch between a light and dark Look-and-Feel package.
- Config settings (light/dark theme ids, icon style, auto-schedule) are stored in `metadata.json` and `main.xml`.
- The panel button shows the current state via the bundled `themetoggle.svg` yin-yang icon.

## License

[GPL-3.0-or-later](LICENSE).

## Release history

### [1.0.0] — Initial release

- One-click theme toggle between light and dark Global Themes
- Optional time-of-day auto-schedule
- Two icon styles: Yin-Yang, Sun-Moon
- Configurable click action and per-mode color customization for Yin-Yang

### [1.0.1] — Patch release

- [Placeholder]
