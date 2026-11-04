# The Linux build container (linux/Dockerfile), sourced by the linux-*.sh scripts. LINUX_ARCH is arm64 (native on
# Apple silicon) or amd64 (through Rosetta in OrbStack); the first argument of a script sets it where it takes one
LINUX_ARCH=${LINUX_ARCH:-arm64}
case "$LINUX_ARCH" in
arm64 | amd64) ;;
*)
    echo "the architecture is arm64 or amd64, not $LINUX_ARCH" >&2
    exit 2
    ;;
esac
LINUX_IMAGE="inbox-classic-linux:$LINUX_ARCH"
# the Cargo target directory in the container, under build/ of the mounted tree so nothing lands in the sources
LINUX_TARGET="/src/build/cargo-linux-$LINUX_ARCH"

# builds the image when the Dockerfile changed (Docker's cache makes it quick otherwise)
linux_image() {
    docker build --quiet --platform "linux/$LINUX_ARCH" -t "$LINUX_IMAGE" -f linux/Dockerfile linux >/dev/null
}

# the shell command that installs ImapKit's node_modules in the container, once for each package-lock.json
LINUX_E2E_MODULES='(cd /src/core/e2e && stamp=$(sha256sum package-lock.json) &&
    if [ "$(cat node_modules/.lock-stamp 2>/dev/null)" != "$stamp" ]; then
        npm ci --no-audit --no-fund --silent && echo "$stamp" > node_modules/.lock-stamp
    fi)'

# runs a shell command in the container with the tree at /src: the crates downloaded once into a volume, ImapKit's
# node_modules in a volume of their own (the Mac's in core/e2e are not for Linux). Extra docker options in LINUX_DOCKER
linux_run() {
    linux_image
    local tty=-i
    [ -t 0 ] && [ -t 1 ] && tty=-it
    # shellcheck disable=SC2086
    docker run --rm "$tty" --platform "linux/$LINUX_ARCH" \
        -v "$PWD:/src" \
        -v "inbox-classic-cargo-registry-$LINUX_ARCH:/opt/cargo/registry" \
        -v "inbox-classic-e2e-modules-$LINUX_ARCH:/src/core/e2e/node_modules" \
        -e CARGO_TARGET_DIR="$LINUX_TARGET" -e CARGO_TERM_COLOR=always \
        ${LINUX_DOCKER:-} -w /src/linux "$LINUX_IMAGE" bash -euo pipefail -c "$1"
}
