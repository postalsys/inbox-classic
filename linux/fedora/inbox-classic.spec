# The recipe of the Fedora package, kept in https://github.com/postalsys/inbox-classic as linux/fedora/inbox-classic.spec.
# scripts/fedora-package.sh builds it on Fedora 44 (the oldest Fedora with the GTK and libadwaita it needs, so one
# package installs on 44 and newer) with scripts/fedora-rpmbuild.sh, which CI's fedora job runs too. The crates are
# fetched in the prep step, as the Arch recipe does: this is built in our own containers, not in Koji or COPR.

Name:           inbox-classic
# x-release-please-start-version
Version:        0.22.0
# x-release-please-end
Release:        1%{?dist}
Summary:        A fast, simple mail program
License:        MIT
URL:            https://inboxclassic.com
Source0:        https://github.com/postalsys/inbox-classic/archive/refs/tags/v%{version}/%{name}-%{version}.tar.gz
ExclusiveArch:  x86_64 aarch64

BuildRequires:  cargo >= 1.92
BuildRequires:  rust >= 1.92
BuildRequires:  gcc
BuildRequires:  pkgconf-pkg-config
BuildRequires:  pkgconfig(gtk4) >= 4.20
BuildRequires:  pkgconfig(libadwaita-1) >= 1.8
BuildRequires:  pkgconfig(webkitgtk-6.0)
BuildRequires:  /usr/bin/node
BuildRequires:  desktop-file-utils
BuildRequires:  libappstream-glib
BuildRequires:  binutils

# the libraries are found by rpm itself; these say the versions the window needs
Requires:       gtk4%{?_isa} >= 4.20
Requires:       libadwaita%{?_isa} >= 1.8
Requires:       hicolor-icon-theme
# keeps the passwords between runs (or another Secret Service provider)
Recommends:     gnome-keyring

# the build has no debug sources to give: no debuginfo package
%global debug_package %{nil}
# a target directory given from outside (scripts/fedora-package.sh keeps one between runs), or the source folder's
%global cargo_target ${CARGO_TARGET_DIR:-%{_builddir}/%{name}-%{version}/target}

%description
Inbox Classic is a mail program for Windows, the Mac and Linux, with the
layout of Outlook Express. IMAP, SMTP and MIME run in its Rust core; on Linux
its window is GTK 4. Everything a server or a sender writes is parsed in Rust,
and messages are shown without scripts.

%prep
%autosetup -n %{name}-%{version}
cd linux
cargo fetch --locked

%build
cd linux
export CARGO_TARGET_DIR="%{cargo_target}"
# no build paths in the binary (the paths of panic messages)
export RUSTFLAGS="${RUSTFLAGS:-} --remap-path-prefix=%{_builddir}=/build"
cargo build --frozen --release
mkdir -p ../build/notices
CARGO_NET_OFFLINE=true node ../scripts/notices.mjs --linux ../build/notices
# the help for Yelp, <language>/inbox-classic/ (English as C)
rm -rf ../build/help
cargo run --frozen --release --example yelp-help -- ../build/help

%install
install -Dm755 "%{cargo_target}/release/inbox-classic" %{buildroot}%{_bindir}/inbox-classic
# no debug package is made, so its symbols are left out here
strip %{buildroot}%{_bindir}/inbox-classic
install -Dm644 linux/data/com.inboxclassic.InboxClassic.desktop -t %{buildroot}%{_datadir}/applications
install -Dm644 linux/data/com.inboxclassic.InboxClassic.metainfo.xml -t %{buildroot}%{_metainfodir}
install -Dm644 app/res/app-icon.svg %{buildroot}%{_datadir}/icons/hicolor/scalable/apps/com.inboxclassic.InboxClassic.svg
install -Dm644 build/notices/THIRD-PARTY-NOTICES.txt -t %{buildroot}%{_docdir}/%{name}
(cd build/help && find . -type f -exec install -Dm644 {} %{buildroot}%{_datadir}/help/{} \;)
# the package repository (rpm.inboxclassic.com), which %%post adds to dnf's repositories, and the key its packages and
# metadata are signed with, which the repository names: never fetched from the repository's own host
install -Dm644 linux/data/inboxclassic.repo linux/data/RPM-GPG-KEY-inboxclassic -t %{buildroot}%{_datadir}/%{name}

%check
desktop-file-validate %{buildroot}%{_datadir}/applications/com.inboxclassic.InboxClassic.desktop
appstream-util validate-relax --nonet %{buildroot}%{_metainfodir}/com.inboxclassic.InboxClassic.metainfo.xml

# The Inbox Classic repository is added when the package is installed, so that a package downloaded from the
# homepage gets its updates with the system's own, as the .deb does with apt. Nothing is added when a repository file
# names it already, or when /etc/default/inbox-classic says DNF_REPOSITORY=no. Removing the package removes the file
# it added, unless it was changed.
%post
if [ "$1" -eq 1 ]; then
    DNF_REPOSITORY=yes
    [ ! -r /etc/default/inbox-classic ] || . /etc/default/inbox-classic
    if [ "$DNF_REPOSITORY" != no ] && ! grep -qs rpm.inboxclassic.com /etc/yum.repos.d/*.repo; then
        install -m 644 %{_datadir}/%{name}/inboxclassic.repo /etc/yum.repos.d/inboxclassic.repo || :
    fi
fi

%preun
# before the files are gone, so the shipped copy is still there to compare with
if [ "$1" -eq 0 ] && cmp -s %{_datadir}/%{name}/inboxclassic.repo /etc/yum.repos.d/inboxclassic.repo; then
    rm -f /etc/yum.repos.d/inboxclassic.repo
fi

%files
%license LICENSE
%{_bindir}/inbox-classic
%{_datadir}/applications/com.inboxclassic.InboxClassic.desktop
%{_metainfodir}/com.inboxclassic.InboxClassic.metainfo.xml
%{_datadir}/icons/hicolor/scalable/apps/com.inboxclassic.InboxClassic.svg
%{_datadir}/help/*/inbox-classic/
%{_datadir}/%{name}/
%doc %{_docdir}/%{name}/THIRD-PARTY-NOTICES.txt

%changelog
* Wed Nov 25 2026 Postal Systems OÜ <info@postalsys.com> - 0.21.0-1
- The first Fedora package; the release notes are at https://github.com/postalsys/inbox-classic/releases
