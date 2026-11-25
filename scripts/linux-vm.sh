#!/usr/bin/env bash
# An Ubuntu Desktop 26.04 (arm64) virtual machine in QEMU on this Mac, for what only a real desktop shows: GNOME on
# Wayland, the tray icon, notifications, the dock's count, the portal file dialogs, installing the .deb and the
# mailto: registration. The disk and the sockets live in build/vm/. DISTRO=fedora makes and runs a Fedora Workstation
# 45 (aarch64) one instead, in build/vm-fedora/ with ssh on port 2223, and `run` installs the .rpm of dist/
# (scripts/fedora-package.sh aarch64): its GNOME has no tray host, which is what it is for.
#
#   scripts/linux-vm.sh create       downloads the installer image, makes the disk and boots the installer in a window.
#                                    Install once by hand (about 15 minutes): user "inbox" (uid 1000), automatic login,
#                                    then in the VM `sudo apt install openssh-server` (Fedora: `sudo systemctl enable
#                                    --now sshd`) and add ~/.ssh/id_*.pub of this
#                                    Mac to ~/.ssh/authorized_keys. When it is done, stop the VM: `create` then makes a
#                                    snapshot "installed" of the disk to return to (qemu-img snapshot -a installed)
#   scripts/linux-vm.sh start        boots the installed VM in a window (hvf, virtio GPU with GL, ssh on port 2222)
#   scripts/linux-vm.sh stop         shuts it down (ACPI power button over QMP)
#   scripts/linux-vm.sh ssh [cmd]    a shell in the VM, or a command
#   scripts/linux-vm.sh run          the .deb of dist/ (scripts/linux-package.sh arm64) installed and the app started
#                                    on the desktop, as scripts/win-run.sh does on Windows
#   scripts/linux-vm.sh screenshot [file]  a picture of the VM's screen from outside (QMP screendump), as a PNG
#
# Needs QEMU from Homebrew (brew install qemu); `screenshot` needs ImageMagick for the PNG (brew install imagemagick).
set -euo pipefail
cd "$(dirname "$0")/.."

DISTRO=${DISTRO:-ubuntu}
case "$DISTRO" in
ubuntu)
    VM=build/vm
    DISK=$VM/ubuntu-26.04.qcow2
    ISO=$VM/ubuntu-26.04-desktop-arm64.iso
    ISO_URL=${ISO_URL:-https://cdimage.ubuntu.com/releases/26.04/release/ubuntu-26.04-desktop-arm64.iso}
    SSH_PORT=${SSH_PORT:-2222}
    PACKAGE=dist/InboxClassic-arm64.deb
    BUILD="scripts/linux-package.sh arm64"
    INSTALL="sudo apt-get install -y"
    ;;
fedora)
    VM=build/vm-fedora
    DISK=$VM/fedora-45.qcow2
    ISO=$VM/Fedora-Workstation-Live-45-1.4.aarch64.iso
    ISO_URL=${ISO_URL:-https://dl.fedoraproject.org/pub/fedora/linux/releases/45/Workstation/aarch64/iso/Fedora-Workstation-Live-45-1.4.aarch64.iso}
    SSH_PORT=${SSH_PORT:-2223}
    PACKAGE=dist/InboxClassic-aarch64.rpm
    BUILD="scripts/fedora-package.sh aarch64"
    INSTALL="sudo dnf install -y"
    ;;
*)
    echo "DISTRO is ubuntu or fedora, not $DISTRO" >&2
    exit 2
    ;;
esac
VARS=$VM/efi-vars.fd
QMP=$VM/qmp.sock
VM_USER=${VM_USER:-inbox}
PREFIX=$(brew --prefix 2>/dev/null || echo /opt/homebrew)
FIRMWARE=$PREFIX/share/qemu/edk2-aarch64-code.fd

# the machine: Apple's hypervisor, 6 cores, 8 GB, UEFI, a virtio GPU with GL shown in a Cocoa window, USB keyboard
# and tablet, the network with ssh forwarded, and a QMP socket for stop and screenshot
qemu() {
    qemu-system-aarch64 \
        -M virt -accel hvf -cpu host -smp 6 -m 8G \
        -drive "if=pflash,format=raw,readonly=on,file=$FIRMWARE" \
        -drive "if=pflash,format=raw,file=$VARS" \
        -device virtio-gpu-gl-pci -display cocoa,gl=es \
        -device qemu-xhci -device usb-kbd -device usb-tablet \
        -device virtio-net-pci,netdev=net0 -netdev "user,id=net0,hostfwd=tcp::$SSH_PORT-:22" \
        -drive "if=virtio,format=qcow2,file=$DISK" \
        -qmp "unix:$QMP,server,nowait" \
        "$@"
}

# one command over QMP (the handshake first)
qmp() {
    printf '{"execute":"qmp_capabilities"}\n%s\n' "$1" | nc -U "$QMP" -w 2 >/dev/null
}

vm_ssh() {
    ssh -p "$SSH_PORT" -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile="$VM/known_hosts" "$VM_USER@127.0.0.1" "$@"
}

case "${1:-}" in
create)
    mkdir -p "$VM"
    [ -f "$FIRMWARE" ] || { echo "no UEFI firmware at $FIRMWARE: brew install qemu" >&2; exit 1; }
    [ -f "$ISO" ] || curl -fL --progress-bar -o "$ISO" "$ISO_URL"
    [ -f "$DISK" ] || qemu-img create -f qcow2 "$DISK" 40G
    [ -f "$VARS" ] || dd if=/dev/zero of="$VARS" bs=1m count=64 2>/dev/null
    qemu -drive "if=none,id=cd,format=raw,readonly=on,file=$ISO" -device usb-storage,drive=cd,bootindex=0
    qemu-img snapshot -c installed "$DISK"
    echo "installed; the snapshot \"installed\" is the clean system"
    ;;
start)
    [ -f "$DISK" ] || { echo "no VM yet: scripts/linux-vm.sh create" >&2; exit 1; }
    qemu -daemonize
    echo "started; ssh on port $SSH_PORT"
    ;;
stop)
    qmp '{"execute":"system_powerdown"}'
    ;;
ssh)
    shift
    vm_ssh "$@"
    ;;
run)
    [ -f "$PACKAGE" ] || { echo "no $PACKAGE: $BUILD" >&2; exit 1; }
    scp -P "$SSH_PORT" -o UserKnownHostsFile="$VM/known_hosts" "$PACKAGE" "$VM_USER@127.0.0.1:/tmp/"
    vm_ssh "$INSTALL /tmp/$(basename "$PACKAGE") && pkill -x inbox-classic || true"
    # on the user's desktop session (SSH has none of its own)
    vm_ssh 'WAYLAND_DISPLAY=wayland-0 XDG_RUNTIME_DIR=/run/user/$(id -u) DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus systemd-run --user --scope inbox-classic >/dev/null 2>&1 &'
    ;;
screenshot)
    out=${2:-screenshot.png}
    ppm="$PWD/$VM/screen.ppm"
    rm -f "$ppm"
    qmp "{\"execute\":\"screendump\",\"arguments\":{\"filename\":\"$ppm\"}}"
    for _ in 1 2 3 4 5 6 7 8 9 10; do [ -s "$ppm" ] && break; sleep 0.3; done
    magick "$ppm" "$out"
    echo "$out"
    ;;
*)
    sed -n '2,24p' "$0" | sed 's/^# \{0,1\}//'
    exit 2
    ;;
esac
