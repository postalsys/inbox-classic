# Fedora packages

How Inbox Classic reaches Fedora, decided on 2026-11-25, and what was found about other RPM distributions.

## What ships

- One RPM per architecture (`InboxClassic-x86_64.rpm`, `InboxClassic-aarch64.rpm`), built from `linux/fedora/inbox-classic.spec` on Fedora 44, the oldest Fedora with the GTK (4.20) and libadwaita (1.8) the window needs, so it installs on 44 and every newer one. `scripts/fedora-package.sh` installs each on clean Fedora 44 and 45 containers and starts it; CI's `fedora` job builds it, runs the UI test on Fedora 44 and installs it there (not a gate yet, as Arch's).
- The packages are signed on the release Mac with the release key (`scripts/rpm-sign.sh`, `brew install rpm`) before `hashes.txt`, so GitHub and the repository hold the same files.
- The dnf repository https://rpm.inboxclassic.com is a static Caddy vhost on srv-04 (`/var/www/rpm.inboxclassic.com`, a DNS-only A record in Cloudflare, no access log), filled by `scripts/dnf-repo.sh` after each release: the packages under `packages/` (every version kept), the metadata under `repodata/` (only the newest), `repomd.xml` signed for `repo_gpgcheck`. `STAGING=<name>` publishes under `/<name>/` to try the whole path.
- The package adds `/etc/yum.repos.d/inboxclassic.repo` when it is installed (as the .deb adds its apt source; `DNF_REPOSITORY=no` in `/etc/default/inbox-classic` leaves it out) and removes it with the package when it was not changed. The key comes with the package (`/usr/share/inbox-classic/RPM-GPG-KEY-inboxclassic`) and the repository file names it there: the repository's host never serves the key, so whoever could write to it could not swap the key.
- Users install the RPM from GitHub (`sudo dnf install https://github.com/postalsys/inbox-classic/releases/latest/download/InboxClassic-x86_64.rpm`); updates then come with `dnf upgrade`.

## The desktop

Fedora Workstation's GNOME has no tray host without an extension such as AppIndicator. Inbox Classic finds none (`linux/src/tray.rs`) and then ends when its window is closed, as GNOME apps do (`App::close_main`), so it never keeps running out of sight. `DISTRO=fedora scripts/linux-vm.sh` makes a Fedora Workstation 45 VM to look at it on a real desktop (installed by hand once, as the Ubuntu one).

## Other RPM distributions

Checked on 2026-11-25; not supported, recorded so the question need not be asked again:

- **openSUSE Tumbleweed**: the Fedora package does not install. Its dependencies use Fedora's package names (`gtk4(aarch-64) >= 4.20`), where openSUSE has `libgtk-4-1`. Its GTK and libadwaita are new enough, so a recipe of its own (or an openSUSE Build Service project) would work.
- **RHEL, AlmaLinux and Rocky Linux 10**: GTK 4.16 and libadwaita 1.6, below the 4.20 and 1.8 the window needs.
- Others (Silverblue and the other immutable Fedoras): the Flatpak manifest in `linux/flatpak` fits them better; it is not released yet.
