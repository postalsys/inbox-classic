# Where the Windows build machine is, sourced by the win-*.sh scripts. Override with WIN_HOST and WIN_DIR
WIN_HOST=${WIN_HOST:-andri@10.8.0.8}
# the source and build directory on that machine, in Windows form
WIN_DIR=${WIN_DIR:-'C:\Users\andri\src\postal-express'}
# the same with forward slashes, for scp and tar
WIN_DIR_FWD=${WIN_DIR//\\//}

# copies the working tree (not the build outputs) to the Windows machine
win_sync() {
    ssh "$WIN_HOST" "if not exist $WIN_DIR mkdir $WIN_DIR"
    # as a file, copied with scp and unpacked there: a tar piped into ssh can hang once the remote end is done
    local archive
    archive=$(mktemp -t inbox-classic-src).tgz
    COPYFILE_DISABLE=1 tar -czf "$archive" --exclude build --exclude dist --exclude .git --exclude core/target \
        --exclude core/fuzz/target --exclude node_modules .
    scp -q "$archive" "$WIN_HOST:$WIN_DIR_FWD/../inbox-classic-src.tgz"
    rm -f "$archive"
    ssh "$WIN_HOST" "tar -xzf $WIN_DIR_FWD/../inbox-classic-src.tgz -C $WIN_DIR_FWD && del $WIN_DIR\\..\\inbox-classic-src.tgz"
}
