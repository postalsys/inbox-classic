# The Linux build and test environment of Inbox Classic: Ubuntu 26.04 with the GTK 4, libadwaita and WebKitGTK
# development files, current stable Rust from rustup (Ubuntu's own rustc is older than the workspace wants), Node 24
# from the official tarball for ImapKit, and Xvfb with a D-Bus session for the headless UI end-to-end test.
# scripts/linux-build.sh, linux-test.sh, linux-ui-e2e.sh and linux-package.sh run in it; CI installs the same packages.
FROM ubuntu:26.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential pkg-config ca-certificates curl xz-utils git dpkg-dev \
        libgtk-4-dev libadwaita-1-dev libwebkitgtk-6.0-dev libdbus-1-dev \
        xvfb xauth dbus dbus-x11 at-spi2-core gnome-keyring libsecret-tools \
        fonts-dejavu-core fonts-cantarell adwaita-icon-theme \
    && rm -rf /var/lib/apt/lists/*

# current stable Rust for every user of the image (the scripts run it as the caller's uid)
ENV RUSTUP_HOME=/opt/rustup CARGO_HOME=/opt/cargo PATH=/opt/cargo/bin:/opt/node/bin:$PATH
RUN curl -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal --default-toolchain stable \
        --component clippy --component rustfmt \
    && cargo install --locked cargo-deb@3.8.0 \
    && chmod -R a+rwX /opt/rustup /opt/cargo

# Node 24 for ImapKit (core/e2e), from nodejs.org. Unpacked with bsdtar: GNU tar fails to create its files
# ("Function not implemented") in an amd64 image under Rosetta
ARG NODE_VERSION=24.11.1
RUN apt-get update && apt-get install -y --no-install-recommends libarchive-tools && rm -rf /var/lib/apt/lists/* \
    && arch=$(dpkg --print-architecture | sed 's/amd64/x64/') \
    && mkdir -p /opt/node \
    && curl -sSfL -o /tmp/node.tar.xz "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${arch}.tar.xz" \
    && bsdtar -xf /tmp/node.tar.xz -C /opt/node --strip-components 1 \
    && rm /tmp/node.tar.xz \
    && node --version
