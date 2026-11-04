#!/usr/bin/env bash
# Runs a command in the Linux build container (linux/Dockerfile) in linux/ with the tree at /src, or a shell without
# one: scripts/linux-shell.sh 'cargo tree -i glib'. LINUX_ARCH=amd64 for the x86_64 container
set -euo pipefail
cd "$(dirname "$0")/.."
. scripts/linux-env.sh
linux_run "${1:-bash -i}"
