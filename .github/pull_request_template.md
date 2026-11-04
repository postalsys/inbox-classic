<!-- What this changes, and why -->

### Every platform

A feature or a change of behavior lands on Windows, the Mac and Linux in the same PR (CLAUDE.md, "Three apps").

- [ ] The core does the work, with its tests (`core/`)
- [ ] `core/commands.toml` or the C API, when a command or an export changed
- [ ] Windows (`app/`), Mac (`mac/`) and Linux (`linux/`)
- [ ] The UI end-to-end test of each platform, and `scripts/feature-map.mjs` for a new feature
- [ ] The help (`core/crates/pe-html/src/help.html`), with `<!--os:...-->` parts where the platforms differ

Left for later on a platform (label the PR `shells: partial`):
