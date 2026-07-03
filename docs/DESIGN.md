# Design notes

This document captures the *why* behind the structure of the widget. It's not a user manual — that lives in the top-level [`README.md`](../README.md) and the comments in each source file.

## Target

**Plasma 6 only.** Plasma 5.27 is upstream-EOL since June 2024 and the KDE Store is dominated by Plasma 6 entries. Maintaining a Plasma 5 branch is a tax that doesn't pay back.

## Positioning

Plasma 6.5 gained built-in scheduled day/night Global Theme switching, which absorbs the "scheduled switcher" use case for up-to-date systems. This widget's reason to exist is therefore (1) the one-click panel toggle with visible state, (2) per-component switching that doesn't clobber user customizations — the v0.2 headline, see [`ROADMAP.md`](ROADMAP.md) — and (3) scheduling for the long tail of Plasma 6.0–6.4 installs (e.g. Debian 13). Scheduling stays a feature but is no longer the pitch.

## Config tabs

Three tabs, defined in [`package/contents/config/config.qml`](../package/contents/config/config.qml). The settings are typed in [`package/contents/config/main.xml`](../package/contents/config/main.xml) (KConfigXT) — which is what generates the `cfg_<name>` properties that the QML config pages bind to.

### General

Two `ComboBox`es: *Light theme* and *Dark theme*, each populated by parsing `plasma-apply-lookandfeel --list` at config-open time. The user picks Look-and-Feel package ids — the same things System Settings → Global Theme shows. 90% of users want this and nothing else.

Plus *Click action* (Toggle / Show menu / Cycle) and *Icon style* (Follow scheme / Sun-moon / Yin-yang).

### Auto switch

The time-of-day requirement.

- Master `CheckBox` "Switch theme automatically based on time of day". All other rows in the tab disable when this is off.
- *Mode* dropdown: **Fixed times** (functional) and **Sunrise / sunset (coming soon)** (placeholder; refuses to commit when selected).
- Two paired `SpinBox` rows for *Light theme starts at* and *Dark theme starts at*. Hours `0–23` and minutes `0–59`, stored as `"HH:MM"` strings. Qt Quick has no native time picker — paired SpinBoxes are the idiomatic minimal answer; we can swap in a `Kirigami.PromptDialog`-based picker later if it feels clunky.
- *Notification* toggle.
- An `InlineMessage` explains the schedule semantics so users aren't confused about what happens during suspend.

### Advanced

Stubbed for v0.1: a single "Override individual theme components" checkbox plus an `InlineMessage` saying it's coming in v0.2. This is not a nice-to-have — per-component switching is the widget's differentiator (see *Positioning*) and the main v0.2 deliverable. The full Advanced tab will expose two ComboBoxes per component (one for the light state, one for the dark state) for: Color Scheme, Plasma Style, Window Decoration, Icon Theme, Cursor Theme, Wallpaper, GTK theme. Each defaults to "From Global Theme" and only takes effect when explicitly set; selected components are applied individually (`plasma-apply-colorscheme`, `plasma-apply-desktoptheme`, …) so everything else is left untouched.

## Widget logic — `main.qml`

### Theme application

From QML we shell out to `plasma-apply-lookandfeel --apply <id>` via `org.kde.plasma5support.DataSource`. The `plasma5support` module is the Plasma 6 module that wraps process execution — confusingly named for backward-compat reasons; it is the right module to use in Plasma 6 widgets.

State is tracked via `Plasmoid.configuration.lastAppliedWasDark` (a Bool persisted by KConfigXT). The toggle just flips the bit and applies the other theme. Reading kdeglobals to *infer* the current state would be more "correct" but more fragile (Global Theme name vs. Color Scheme name vs. Look-and-Feel id are not the same string, and a user changing themes from outside the widget would desync us anyway).

### Schedule ticker

```qml
Timer {
    id: scheduleTicker
    interval: 30 * 1000
    running: Plasmoid.configuration.autoSwitchEnabled
    repeat: true
    triggeredOnStart: true
    onTriggered: root.checkSchedule()
}
```

`checkSchedule()` does **not** fire-and-forget at the boundary. Instead, on every tick it computes which side of the schedule "now" falls on and re-applies the theme **only if** it differs from `lastAppliedWasDark`. This single design choice handles three otherwise-tricky cases for free:

1. **Suspend across a switch time.** Laptop sleeps at 18:50, wakes at 19:30, with `darkTime=19:00`. On the next tick after wake (at most 30s later), `checkSchedule()` notices `shouldBeDark=true` and `lastAppliedWasDark=false`, applies dark theme. Done.
2. **Missed ticks.** If the timer fires late or twice, the desired state is still computed correctly each time — no double-applies, no missed transitions.
3. **User toggles manually mid-day.** User clicks the widget at noon to switch to dark even though `lightTime=07:00 < now < darkTime=19:00`. `lastAppliedWasDark` becomes true. On the next tick `checkSchedule()` sees `shouldBeDark=false` (it's still daytime by the schedule) and **switches back**. Whether this is the right UX is debatable; if not, we add a "manual override expires at next boundary" mode in v0.2.

The boundary computation handles both `lightStart < darkStart` (the normal case, light during the day) and `darkStart < lightStart` (a hypothetical user who wants dark during the day) — see the `if (lightStart < darkStart)` branch in `main.qml`.

### Icon

Three icon modes:

1. **Follow scheme** (default): the panel icon switches between `preferences-desktop-theme-global` (when light is applied) and `preferences-desktop-color` (when dark is applied). Inherits from the user's icon theme so it always matches.
2. **Sun / moon**: explicit `weather-clear` / `weather-clear-night` from the icon theme.
3. **Yin-yang**: the bundled `themetoggle.svg`, currently a simple two-tone SVG (black-and-white for now; should probably be re-themed to use Breeze color tokens before the public release so it adapts to both light and dark panels).

## Theme enumeration — option (a) vs (b)

Pure-QML cannot list KPackages directly. Two options:

- **(a) Shell out** to `plasma-apply-lookandfeel --list` via `P5Support.DataSource` at config-open time, parse stdout into a `ListModel`. Ugly, ~100ms first-open delay, **zero build complexity**.
- **(b) Ship a tiny C++ KPackage enumeration plugin.** Clean and fast, but now the widget needs CMake, build deps, per-distro packaging — kills the "drop a zip on the KDE Store" workflow.

**Decision: (a) for v0.1.** Move to (b) only if users complain.

The downside of (a) is that the parsed line gives us only the id, not a human-friendly name. For Look-and-Feel packages the id is reverse-DNS and reasonably recognisable (`org.kde.breezedark.desktop`), so users can pick from it. v0.2 can call `kpackagetool6 --type Plasma/LookAndFeel --show <id>` per item to fetch the proper Name field, or just bite the bullet and ship the C++ plugin.

## Testing strategy

See [`../tests/README.md`](../tests/README.md) for the operational details. The high-level layering:

| Layer | What | Who |
|---|---|---|
| 1 | `plasmoidviewer6` inside a distrobox | Dev loop, every save |
| 2 | Same script against multiple Plasma versions / distros | Pre-release |
| 3 | Real Plasma 6 session in a VM (Multipass / virt-manager) | Pre-release |
| 4 | Real users | Post-release |

A Plasma 5 host **cannot run plasmoidviewer6** (it ships only the Plasma 5 `plasmoidviewer` binary, which can't load Plasma 6 widgets — different QML imports). This is the reason for the distrobox-with-KDE-neon arrangement: the host OS is irrelevant, only the in-container Plasma version matters.

## Out of scope for v0.1

See [`ROADMAP.md`](ROADMAP.md) for where each of these lands.

- The KDE Store upload itself (manual one-time step).
- Translations (`po/` + Weblate). Added if/when the widget gets traction.
- C++ KPackage enumeration plugin.
- Sunrise/sunset auto-switch logic.
- Per-component override UI (v0.2 headline).
- GitHub Actions / KDE Invent CI.
