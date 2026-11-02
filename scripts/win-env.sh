# Where the Windows build machine is, sourced by the win-*.sh scripts. Override with WIN_HOST and WIN_DIR
WIN_HOST=${WIN_HOST:-andri@10.8.0.8}
# the source and build directory on that machine, in Windows form
WIN_DIR=${WIN_DIR:-'C:\Users\andri\src\postal-express'}
# the same with forward slashes, for scp and tar
WIN_DIR_FWD=${WIN_DIR//\\//}

# copies the working tree (not the build outputs) to the Windows machine
win_sync() {
    ssh "$WIN_HOST" "if not exist $WIN_DIR mkdir $WIN_DIR"
    COPYFILE_DISABLE=1 tar -czf - --exclude build --exclude dist --exclude .git --exclude core/target --exclude node_modules . | ssh "$WIN_HOST" "tar -xzf - -C $WIN_DIR_FWD"
}
