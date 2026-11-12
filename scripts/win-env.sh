# Where the Windows build machine is, sourced by the win-*.sh scripts. Override with WIN_HOST and WIN_DIR
WIN_HOST=${WIN_HOST:-andri@10.8.0.8}
# the source and build directory on that machine, in Windows form
WIN_DIR=${WIN_DIR:-'C:\Users\andri\src\postal-express'}
# the same with forward slashes, for scp and tar
WIN_DIR_FWD=${WIN_DIR//\\//}
# the copy's archive and the note of where it came from, beside that directory and named by it, so two checkouts
# copied to two directories at once do not take each other's
WIN_COPY=${WIN_DIR_FWD##*/}-src

# copies the working tree (not the build outputs) to the Windows machine
win_sync() {
    ssh -n "$WIN_HOST" "if not exist $WIN_DIR\\core mkdir $WIN_DIR\\core"
    # as a file, copied with scp and unpacked there: a tar piped into ssh can hang once the remote end is done
    local archive
    archive=$(mktemp -t inbox-classic-src).tgz
    COPYFILE_DISABLE=1 tar -czf "$archive" --exclude build --exclude dist --exclude .git --exclude core/target \
        --exclude core/fuzz/target --exclude node_modules .
    scp -q "$archive" "$WIN_HOST:$WIN_DIR_FWD/../$WIN_COPY.tgz"
    rm -f "$archive"
    # from another checkout than last time, the sources it left go first (a crate only it has would join the cargo
    # workspace), keeping the build outputs, and the files get the time of the copy (-m): their own times can be older
    # than what was built from the other checkout, which cargo and CMake would then take as up to date
    local here keep=""
    here=$(pwd -P)
    if [ "$(ssh -n "$WIN_HOST" "type $WIN_DIR\\..\\$WIN_COPY.from 2>nul" | tr -d "\r")" != "$here" ]; then
        keep="-m"
        ssh -n "$WIN_HOST" "powershell -NoProfile -Command \"Get-ChildItem -Force '$WIN_DIR' | Where-Object { \$_.Name -notin 'build','dist','core' } | Remove-Item -Recurse -Force; Get-ChildItem -Force '$WIN_DIR\\core' -ErrorAction SilentlyContinue | Where-Object { \$_.Name -ne 'target' } | Remove-Item -Recurse -Force\""
    fi
    ssh -n "$WIN_HOST" "tar $keep -xzf $WIN_DIR_FWD/../$WIN_COPY.tgz -C $WIN_DIR_FWD && del $WIN_DIR\\..\\$WIN_COPY.tgz"
    ssh -n "$WIN_HOST" "echo $here> $WIN_DIR\\..\\$WIN_COPY.from"
}
