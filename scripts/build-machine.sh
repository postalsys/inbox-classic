#!/usr/bin/env bash
# Runs one of this repository's Linux scripts on the build machine (scripts/win-env.sh), in its WSL Ubuntu with Docker
# Engine and arm64 emulation (qemu), on a copy of this working tree, then brings back what it made:
#
#   scripts/build-machine.sh [--fetch <path>]... <script> [arguments]
#   scripts/build-machine.sh --fetch 'dist/InboxClassic-*.deb' scripts/linux-package.sh amd64
#
# The copy is the files git knows (as git ls-files lists them, committed or not), kept in ~/src/<checkout> in WSL with
# its build/ and dist/ between runs, so cargo's builds there stay warm; each --fetch path (a shell pattern, relative
# to the tree) is copied back into this tree afterwards. It runs as root there: the containers write build/ and dist/
# as root, which a user could then not clean up. What is the machine's own (UBUNTU_MIRROR, for one) is in its
# /root/.build-machine.env, read before the script runs. The machine has nothing else to do: the WSL VM has all its
# processors and most of its memory (%USERPROFILE%\.wslconfig), and the builds use them all.
set -euo pipefail
cd "$(dirname "$0")/.."
. scripts/win-env.sh
WSL_DISTRO=${WSL_DISTRO:-Ubuntu-24.04}
fetch=()
while [ "${1:-}" = "--fetch" ]; do
    fetch+=("$2")
    shift 2
done
[ $# -gt 0 ] || {
    echo "usage: scripts/build-machine.sh [--fetch <path>]... <script> [arguments]" >&2
    exit 2
}
name=$(basename "$(pwd -P)")
# beside the Windows checkout, where WSL reads them at /mnt/c
win_side="${WIN_DIR_FWD%/*}"
wsl_side="/mnt/c${win_side#C:}"
job="$name-linux"

archive=$(mktemp -t inbox-classic-linux).tgz
trap 'rm -f "$archive"' EXIT
git ls-files -z --cached --others --exclude-standard | COPYFILE_DISABLE=1 tar --null --no-xattrs -T - -czf "$archive"
scp -q "$archive" "$WIN_HOST:$win_side/$job.tgz"

# the job: the copy brought up to date (files git no longer has removed, build/ and dist/ kept), the script run, what
# it made packed for the way back
{
    echo 'set -euo pipefail'
    printf 'tree=~/src/%q\n' "$name"
    printf 'side=%q\n' "$wsl_side"
    printf 'job=%q\n' "$job"
    echo 'stage=$(mktemp -d)
mkdir -p "$tree"
tar -xzf "$side/$job.tgz" -C "$stage"
rm -f "$side/$job.tgz" "$side/$job-out.tgz"
rsync -a --delete --exclude /build/ --exclude /dist/ "$stage/" "$tree/"
rm -rf "$stage"
cd "$tree"
if [ -f ~/.build-machine.env ]; then set -a; . ~/.build-machine.env; set +a; fi'
    printf '%q ' "$@"
    echo
    echo 'shopt -s nullglob'
    printf 'out=('
    for path in "${fetch[@]+"${fetch[@]}"}"; do
        printf '%s ' "$path"
    done
    echo ')'
    echo 'if [ ${#out[@]} -gt 0 ]; then tar -czf "$side/$job-out.tgz" "${out[@]}"; fi'
} >"$archive.job"
scp -q "$archive.job" "$WIN_HOST:$win_side/$job.sh"
rm -f "$archive.job"
status=0
ssh -n "$WIN_HOST" "wsl -d $WSL_DISTRO -u root -e bash $wsl_side/$job.sh" || status=$?
if [ ${#fetch[@]} -gt 0 ] && [ "$status" -eq 0 ]; then
    scp -q "$WIN_HOST:$win_side/$job-out.tgz" "$archive"
    tar -xzf "$archive"
    ssh -n "$WIN_HOST" "del ${WIN_DIR%\\*}\\$job-out.tgz"
fi
ssh -n "$WIN_HOST" "del ${WIN_DIR%\\*}\\$job.sh" >/dev/null 2>&1 || true
exit "$status"
