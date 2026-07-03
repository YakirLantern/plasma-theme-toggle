# Roadmap

## v0.1 — first release

- [x] Standalone public repo, clean history, GPL-3.0 + SPDX (REUSE-compliant)
- [ ] First render under real Plasma 6 (`tests/plasmoidviewer-smoke.sh`) and fixes it surfaces
- [ ] Manual install + config-dialog walkthrough in a real Plasma 6 session
- [ ] KDE Store listing (screenshot + description), upload `.plasmoid`

## v0.2 — per-component switching (the differentiator)

Plasma 6.5's built-in scheduler switches whole Global Themes; so does v0.1. Applying a Global Theme resets components users often customize independently. v0.2 makes the Advanced tab real: per-component light/dark pairs for Color Scheme, Plasma Style, Window Decoration, Icon Theme, Cursor Theme, Wallpaper, and GTK theme — each defaulting to "From Global Theme", applied individually (`plasma-apply-colorscheme`, `plasma-apply-desktoptheme`, etc.) so everything not selected is left untouched.

Also under consideration for v0.2:

- "Manual override expires at next schedule boundary" mode (see DESIGN.md, schedule ticker case 3)
- Human-friendly theme names in the config ComboBoxes (via `kpackagetool6 --show`)

## Later / if traction

- Sunrise/sunset schedule mode (geolocation)
- Translations (`po/` + Weblate)
- CI (GitHub Actions running the distrobox smoke test)
- C++ KPackage enumeration plugin (only if the shell-out enumeration proves painful)
