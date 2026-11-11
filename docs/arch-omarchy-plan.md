# Arch Linux and Omarchy: the plan

Inbox Classic on Linux ships today as two `.deb` packages (amd64, arm64, built in Ubuntu 26.04 Docker by `scripts/linux-package.sh`), the signed apt repository `apt.inboxclassic.com` (`scripts/apt-repo.sh`) and a Flatpak manifest (`linux/flatpak/`, not on Flathub yet). Nothing installs on Arch. This plan adds Arch Linux, aimed at Omarchy: someone who has just installed Omarchy should find Inbox Classic in the Omarchy menu, install it in a minute and get its updates with Omarchy's own updates.

## What Omarchy is today

Checked against the Omarchy source at its latest tag, v4.5.0 (`github.com/omacom/omarchy`), and its package repository (`github.com/omacom-io/omarchy-pkgs`):

- **Arch Linux and Hyprland** with its own shell on Quickshell (no Waybar any more), on x86_64 (the official ISO) and aarch64 (Apple Silicon through Asahi, Snapdragon, generic Arch Linux ARM).
- **The Omarchy Package Repository** `pkgs.omarchy.org` comes first in `pacman.conf`, ahead of Arch's own. Its packages are signed with Omarchy's key and built by Omarchy's CI for x86_64 and aarch64. Besides Omarchy itself it carries third-party apps (1password, bitwarden, dropbox, localsend, lmstudio-bin and others), and its README invites package contributions by pull request.
- **Installing**: the Omarchy menu (Super + Alt + Space) has _Install > Package_ (`omarchy-pkg-install`: fzf over `pacman -Slq`, so every package of Omarchy's repository and Arch's) and _Install > AUR_ (`yay`, installed by default). The manual calls the AUR "not vetted" and says the base install uses only Arch's repositories and Omarchy's.
- **Updates**: `omarchy-update` updates the system packages (Omarchy's repository included) and then the AUR packages (`yay -Sua`).
- **Desktop services the app uses**, all present:

| Inbox Classic on Linux                                                | On Omarchy                                                                                                                 | Status                                                                |
| --------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------- |
| Passwords in the Secret Service (`zbus-secret-service-keyring-store`) | `gnome-keyring` is a base package; the installer creates an unlocked `Default_keyring` (`install/user/default-keyring.sh`) | should work, check                                                    |
| Tray icon (`ksni`, StatusNotifierItem)                                | the Quickshell bar has a tray widget (`shell/plugins/bar/widgets/Tray.qml`)                                                | should work, check the menu                                           |
| Notifications (`gio::Notification`, click opens the message)          | the shell is the `org.freedesktop.Notifications` server; a click calls the sender's `default` action                       | check the click raises the window (Hyprland focus and xdg-activation) |
| Unread count on the dock (`com.canonical.Unity.LauncherEntry`)        | no dock                                                                                                                    | nothing shows, nothing to do                                          |
| Browser sign-in (`gtk::UriLauncher`), file dialogs                    | `xdg-desktop-portal-gtk` and `-hyprland`, Chromium as the default browser                                                  | should work, check                                                    |
| GTK 4.20, libadwaita 1.8, WebKitGTK 6.0                               | Arch `extra` (rolling, always at or ahead of Ubuntu 26.04)                                                                 | fine; the risk is the reverse, a newer GTK changing something         |
| Windows: main window, compose, message windows, dialogs               | Hyprland tiles top-level windows; dialogs with a parent float                                                              | check every window and dialog                                         |
| Codes in notifications (0.11.0)                                       | Omarchy's notification shell detects verification codes in notification text itself (`Detect.js`)                          | check the two do not show the code twice or clash                     |

## How a package gets into Omarchy's repository

From the `omarchy-pkgs` README:

1. A pull request adds `pkgbuilds/<name>/PKGBUILD` and `pkgbuilds/<name>/.omarchy/package.json`, one package per PR, saying what the package is and how it was tested. Every git source pinned, checksums filled with `updpkgsums`, `arch=()` listing each architecture (CI builds each one), vendor archives extracted with `bsdtar --no-same-owner`.
2. The first PR of an outside author waits for a maintainer to label it `build-approved` (builds cost machines). Then CI builds every architecture (x86_64 on their droplets, aarch64 on GitHub's ARM runners) and runs the checks `result`, `self-tests` and `build-isolation`.
3. Green, and touching only `pkgbuilds/`, it merges itself; it is signed and published to `edge` within minutes, and reaches `rc` and `stable` when those are promoted. A package on the fast ring (`"release_ring": "fast"`, as localsend has) goes to all three at once; the PR asks for it.
4. **Updates without us**: `.omarchy/package.json` declares `"upstream": { "watch": { "github": "postalsys/inbox-classic", "pattern": "v(?P<version>[0-9]+(?:\\.[0-9]+)*)" } }`. A bot reads our GitHub Releases on a schedule, opens the version bump PR, and it merges itself when it builds. Our tags (`v0.11.0`) match that pattern, and our releases stay drafts until `release.sh` has uploaded everything, so the bot never sees a half-made release.

## Decisions

- **Omarchy's repository first**, with one package, `inbox-classic`, built from the release's source tarball (`archive/v$pkgver.tar.gz`) with cargo, for `x86_64` and `aarch64`. Built by Omarchy's CI against Arch's own libraries, so no Ubuntu binary on Arch. Fast ring requested. Users get it from _Install > Package_ or `sudo pacman -S inbox-classic`, and updates with Omarchy's.
- **The AUR later, for Arch users without Omarchy**, once its registration reopens (closed in November 2026 against automated sign-ups). The same PKGBUILD as `inbox-classic`, from a new `postalsys` account; the key is ready at `~/.ssh/aur_postalsys` on the release Mac. A `-bin` package from the `.deb` only if building from source proves too slow for people.
- **No pacman repository of our own.**
- **No release step for Arch in `release.sh`.** Omarchy's bot picks each release up. `release.sh` only prints the link where the bot's PR appears, so the release can be followed there.
- **The desktop test is a VMware Workstation VM on the Windows laptop** (`andri@10.8.0.8`, 24 cores, 32 GB, VMware Workstation installed, Hyper-V on): official Omarchy from the x86_64 ISO, which matches what most users run. Driven over SSH through the laptop; screenshots from `grim` inside the guest, so a locked or disconnected Windows session does not matter. A QEMU VM on the Mac for aarch64 is a later option.

## The work

### 1. The PKGBUILD (`linux/arch/PKGBUILD`)

Our copy of the recipe: what the Omarchy PR submits, what the AUR gets later, what CI builds.

- `pkgname=inbox-classic`, `arch=(x86_64 aarch64)`, `license=(MIT)`, `url=https://inboxclassic.com`.
- `source=("inbox-classic-$pkgver.tar.gz::https://github.com/postalsys/inbox-classic/archive/v$pkgver.tar.gz")` with its `sha256sums`.
- `depends=(gtk4 libadwaita webkitgtk-6.0 glib2 cairo pango gdk-pixbuf2 graphene gcc-libs glibc)`, checked with `namcap`; `optdepends=('gnome-keyring: keeps the passwords between runs (or another Secret Service provider)')`; `makedepends=(cargo nodejs)` and whatever `glib-build-tools` needs for `glib-compile-resources` (`glib2-devel` on current Arch).
- `prepare()`: `cargo fetch --locked --target "$(rustc --print host-tuple)"` in `linux/`. `build()`: `cargo build --frozen --release`, then `node scripts/notices.mjs --linux`. `package()`: the binary, the desktop file, the metainfo, the icon, `THIRD-PARTY-NOTICES.txt` and the license, as the `.deb` has them; not the apt source file. No `check()`: the tests need ImapKit, and CI runs them.
- Following the Arch Rust packaging guidelines; check whether makepkg's `lto` option needs `options=(!lto)` for the C parts (`ring`, bundled SQLite).
- `pkgver` kept current by release-please (`extra-files`, the generic updater on the `pkgver=` line); the sum only matters for the submitted copy.

Tried locally: in a clone of `omarchy-pkgs`, `bin/build --package inbox-classic` (Docker, the same builder image their CI uses; x86_64 through Rosetta), then the package installed into a clean `archlinux:latest` container and started with `--version`.

### 2. CI: an `arch` job

`.github/workflows/ci.yml` gets an `arch` job in `container: archlinux:latest` on `ubuntu-latest`:

- `pacman -Syu` of the build packages, `cargo build` of `linux/` and the UI end-to-end test under Xvfb (`scripts/linux-ui-e2e-run.sh`), with the feature check. Arch's GTK, libadwaita and WebKitGTK move ahead of Ubuntu's, so this finds a break before an Omarchy user does.
- `makepkg` of `linux/arch/PKGBUILD` pointed at the checkout, and `namcap`. This matters more now: Omarchy's bot builds each release on its own, and a release that fails to build there sits as a red PR and never reaches users.
- It starts as non-blocking for a few weeks (a rolling distribution can break CI on its own schedule), then becomes required.

### 3. The desktop VM (Omarchy in VMware on the Windows laptop)

- `scripts/omarchy-vm.sh` (from the Mac): `create`, `start`, `stop`, `ssh`, `screenshot`, `snapshot`, `revert`, through `ssh -J andri@10.8.0.8` to the guest's SSH (VMware NAT port forward) and `vmrun -T ws ... nogui` on the laptop.
- First, a short trial: Hyprland under VMware Workstation with Hyper-V on (Windows Hypervisor Platform mode) with 3D acceleration; if it does not draw, the settings from Omarchy discussion #572, and software rendering as the fallback.
- One install from the official ISO at the VMware console over RDP, then `openssh` enabled and a snapshot `clean` to return to.
- `screenshot` runs `grim` in the guest (`HYPRLAND_INSTANCE_SIGNATURE` from `/run/user/1000/hypr/`) and copies the PNG to `build/omarchy-vm/`; `hyprctl` moves focus and windows.
- Before the PR: the locally built package installed with `pacman -U`, then the checklist. After it is published: _Install > Package_, `inbox-classic`, from `clean`; after the next release, `omarchy-update` brings it.

The checklist:

- the launcher entry and icon, and the app id `com.inboxclassic.InboxClassic` matching the desktop file (focus-by-app and window rules use it);
- passwords kept across a restart (gnome-keyring, no prompt);
- the tray icon in the Quickshell bar, its menu, hiding to the tray;
- a new mail notification, its click opening the message and raising the window; a code notification next to Omarchy's own code detection;
- the browser sign-in (Outlook.com) through Chromium and back to the app;
- every window and dialog under tiling: compose, message windows, Options, Add Account, file dialogs, Print; their sizes and whether they float;
- an Omarchy theme switch (light and dark) and the libadwaita colors following it;
- `mailto:` links from Chromium opening the compose window.

What it finds is fixed in `linux/` before the PR.

### 4. The pull request to `omacom-io/omarchy-pkgs`

- From a fork: `pkgbuilds/inbox-classic/PKGBUILD` (the copy from step 1 with the 0.11.0 sum) and `pkgbuilds/inbox-classic/.omarchy/package.json`:

    ```json
    {
        "source": "local",
        "release_ring": "fast",
        "upstream": {
            "watch": { "github": "postalsys/inbox-classic", "pattern": "v(?P<version>[0-9]+(?:\\.[0-9]+)*)" }
        }
    }
    ```

- `python helpers/upstream-watch.py check pkgbuilds/inbox-classic` reports it current; `tests/pinned-sources.sh` passes.
- The description, short: what Inbox Classic is, that it builds from the tagged source for both architectures, that it was tried on Omarchy 4.5 (the checklist, a screenshot or two), why the fast ring (a mail client wants its fixes promptly), and that we watch the bot's update PRs and fix a red one.
- Opened by andris9 after you have read it. Then waiting for a maintainer's `build-approved`.

### 5. Following releases

- `release.sh` prints `https://github.com/omacom-io/omarchy-pkgs/pulls?q=inbox-classic` at the end of a Linux release.
- When a dependency changes (a new system library, a new build tool), the PKGBUILD change goes to `omarchy-pkgs` as its own PR with `pkgrel` bumped, as their README says.

### 6. The app, help and docs

- `core/crates/pe-html/src/help.html`: the Linux removal line names apt only; add Arch and Omarchy (`sudo pacman -R inbox-classic`).
- `README.md` "Installing": an Arch Linux and Omarchy paragraph.
- `CLAUDE.md`: the Linux bullet and the release paragraph name the Omarchy package, `linux/arch/PKGBUILD`, the CI job and the VM script.
- `docs/cross-platform-plan.md`: the distribution line.

### 7. The homepage (`../inboxclassic.com`)

- A card next to "How do I get updates on Linux?": **Omarchy**, with the menu path (_Install > Package_, `inbox-classic`) and `sudo pacman -S inbox-classic`, and a line that Omarchy's Update keeps it current. Plain Arch gets its line once the AUR package exists.
- An "Omarchy" link beside "Install with apt" under the Linux download buttons (the user agent does not say Arch, so no automatic choice).
- Later, an Omarchy screenshot from the VM.

## Order

1. The PKGBUILD, built with Omarchy's own tooling and tried in a clean Arch container.
2. The CI `arch` job.
3. The Omarchy VM and the checklist; fixes in `linux/`.
4. The PR to `omarchy-pkgs`; its review and the first publish.
5. Help, README, CLAUDE.md, the homepage, once the package is in Omarchy's repository.
6. The AUR, whenever its registration reopens.

## Results of the first round (November 2026)

- **The package** (`linux/arch/PKGBUILD`) builds with Omarchy's own tooling (`bin/build` with their published builder images) for x86_64 and aarch64, passes their checks (`pinned-sources`, `fast-ring-check`, `upstream-watch.py check`: "already current") and `namcap`, and installs and starts on clean Arch Linux and Arch Linux ARM. The only dependency an Omarchy install lacks is `webkitgtk-6.0` (139 MiB).
- **On Omarchy 4.5.0** (x86_64, official ISO, `scripts/omarchy-vm.sh`): the launcher lists the app with its icon; account setup with autoconfig, IMAP and SMTP work; the password goes to gnome-keyring without a prompt and is used after a restart; the new mail card shows sender, subject and the app icon, and a click switches to the app's workspace, raises the window and opens the message; Omarchy's own code detection adds a Copy code button to a code notification, the code shown once; Sign in with Microsoft opens Chromium at Microsoft's page while the app waits (a real account is needed to finish); Make Default Mail App takes `mailto:` from HEY, and `xdg-open mailto:` opens a filled compose window; compose tiles beside the main window, the attachment chooser (GTK portal) and Print float over it, Preferences is an in-window dialog; an Omarchy light theme turns the app light at once.
- **Fixed**: the tray icon showed as missing (Quickshell's checkerboard) until the next login, as the bar looks icon names up in the themes it read when it started. The tray item now sends its icon as pixmaps (`linux/data/tray`, from `scripts/build-icons.sh`).
- **Seen, not changed**: a menu's sliding submenu (File, Tools) can run past the right edge of the screen, cutting off the shortcut column, when the window touches that edge (Hyprland does not move the popover back); Omarchy's first-boot cards sit over the app's menu until dismissed.
- **The VM itself**: VMware's SVGA3D runs Hyprland, but Quickshell gets no EGL surface and GTK 4's GL renderer loses its Wayland connection (Nautilus as well), so the VM sets `QT_QUICK_BACKEND=software` and `GSK_RENDERER=cairo`; real hardware needs neither, and these checks do not cover GTK's GL renderer, which Omarchy users run. Its guest clock is set to UTC (`rtc.diffFromUTC`), or the install's pacman keys come out "in the future". Snapshots are taken with the VM off (a live one froze the guest), and the console is VNC on the Windows machine's loopback.

## Where it stands

- Steps 1 to 3 are done (this branch): the PKGBUILD, the CI job, the VM and its checks, with the tray fix they found.
- Step 4 waits for the next release, so Omarchy's first build already has the tray fix: then `scripts/arch-package.sh --release` writes the recipe with that release's checksum, and the pull request to `omacom-io/omarchy-pkgs` goes out with the description in the step above.
- Until then, each release carries the built packages, `InboxClassic-x86_64.pkg.tar.zst` and `InboxClassic-aarch64.pkg.tar.zst` (`scripts/arch-package.sh --release` in `release.sh`, from the release's tarball, in `hashes.txt`; 0.11.0's were added to its release afterwards), and the homepage shows `curl -LO <url>` and `sudo pacman -U <file>`: an install for testing, without updates. (pacman wants a signature for a package given as a URL, which would mean importing our key into pacman's keyring; a downloaded file it installs without one. A new Omarchy has no package lists until its first Update.) Once the package is in Omarchy's repository, the homepage and the README switch to _Install > Package_ and `pacman -S`; a package installed with `pacman -U` then updates from Omarchy's repository, as the names are the same.
- Step 6 waits for the AUR's registration to reopen.

## Risks

- **The Omarchy maintainers decline the package**, or keep it waiting. The repository invites contributions and carries other third-party apps, but inclusion is their call. If they decline, the AUR is the path, with the same PKGBUILD, and the menu's _Install > AUR_ finds it.
- **Build time on their aarch64 runners** (4 vCPU) with thin LTO and one codegen unit: likely 20 to 40 minutes per build. Acceptable for them? Ask in the PR if it is a concern; a `-bin` package from our `.deb` is the fallback.
- **Rolling releases.** A new GTK or WebKitGTK can change behavior before Ubuntu sees it, and a release that does not build stays out of Omarchy; the CI job runs against current Arch on every PR.
- **Hyprland in a VM.** 3D in VMware under Hyper-V is the uncertain part; the trial comes first, with software rendering as a fallback (slower but enough for checks).
- **The laptop is also the Windows build machine** and is sometimes unreachable; the VM needs about 8 GB and 6 cores and runs only for checks.

## Later, not in this plan

- The AUR (step 6 above) for Arch users without Omarchy.
- Arch's official `extra` repository: an Arch package maintainer has to adopt it.
- A mention in Omarchy's manual or a default install: the Omarchy team's choice.
- Flathub, already planned separately.
- aarch64 desktop checks in a QEMU VM on the Mac.
