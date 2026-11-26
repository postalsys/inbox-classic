# The working tree as the release's tarball would have it, sourced by arch-package.sh and fedora-package.sh:
#
#   tree_tarball <file.tar.gz> <top folder>
#
# The files git knows (committed or not); in a copy without .git (scripts/build-machine.sh copies just those files)
# every file outside build/ and dist/. With the Mac's tar (bsdtar) or GNU tar, whichever this machine has.
tree_tarball() {
    local out=$1 top=$2
    local rename=(-s "|^|$top/|" --no-mac-metadata)
    if tar --version 2>/dev/null | grep -q 'GNU tar'; then
        rename=(--transform "s|^|$top/|")
    fi
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        git ls-files -z --cached --others --exclude-standard
    else
        find . \( -path ./build -o -path ./dist -o -path ./.git \) -prune -o -type f -printf '%P\0'
    fi | COPYFILE_DISABLE=1 tar --null --no-xattrs "${rename[@]}" -T - -czf "$out"
}
