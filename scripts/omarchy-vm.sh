#!/usr/bin/env bash
# An Omarchy desktop for checking the Arch package where Omarchy users run it: a VMware Workstation VM on the
# Windows build machine (scripts/win-env.sh), installed unattended from the official x86_64 ISO (a cidata drive with
# the answers, Omarchy's "Unattended Installs"), reached from here over SSH through that machine. Screenshots come
# from grim inside the guest, so the Windows desktop session does not matter.
#
#   scripts/omarchy-vm.sh create                    downloads and verifies the ISO, installs, snapshots "clean"
#   scripts/omarchy-vm.sh start | stop | ip
#   scripts/omarchy-vm.sh ssh [command]             as the user "omarchy"; in a command, $GUI sets the session's
#                                                   environment (WAYLAND_DISPLAY, HYPRLAND_INSTANCE_SIGNATURE, ...)
#   scripts/omarchy-vm.sh screenshot out.png        the whole screen, from grim in the session
#   scripts/omarchy-vm.sh console out.png           the VM's screen over VNC, also while it installs
#   scripts/omarchy-vm.sh install <pkg.tar.zst>     pacman -U of a package built by scripts/arch-package.sh
#   scripts/omarchy-vm.sh snapshot <name> | revert <name>   with the VM off (a live snapshot froze the guest)
#
# The guest's password and the SSH key are in build/omarchy-vm/ (never committed); the VM is on VMware's NAT
# network, which only the Windows machine reaches.
set -euo pipefail
cd "$(dirname "$0")/.."
. scripts/win-env.sh
OMARCHY_VERSION=4.5.0
ISO="omarchy-${OMARCHY_VERSION}-x86.iso"
# "Omarchy <pkgs@omarchy.org>", the key of the ISOs and of Omarchy's package repository (the manual, Security)
OMARCHY_KEY=40DFB630FF42BCFFB047046CF0134EE680CAC571
VM_DIR='C:\Users\andri\vms\omarchy'
VM_DIR_FWD=${VM_DIR//\\//}
VMX="${VM_DIR}\\omarchy.vmx"
VMWARE='C:\Program Files (x86)\VMware\VMware Workstation'
MAC=00:50:56:2e:a1:c5
STATE=build/omarchy-vm
KEY="$STATE/id_ed25519"
GUEST_USER=omarchy
mkdir -p "$STATE"
# one SSH connection to the Windows machine, reused by every call and by the jump to the guest
WIN_SSH=(-o ConnectTimeout=10 -o ControlMaster=auto -o "ControlPath=$HOME/.ssh/omarchy-vm-win" -o ControlPersist=120)
GUEST_SSH=(-i "$KEY" -o "ProxyCommand=ssh ${WIN_SSH[*]} -W %h:%p $WIN_HOST" -o StrictHostKeyChecking=no
    -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ConnectTimeout=10)
# the session's environment for a command over SSH: what uwsm gave the systemd user manager (OMARCHY_PATH and the
# rest), the Wayland socket and the Hyprland instance of the user
GUI='set -a; eval "$(systemctl --user show-environment)"; set +a; export XDG_RUNTIME_DIR=/run/user/$(id -u); export WAYLAND_DISPLAY=$(basename "$(ls $XDG_RUNTIME_DIR/wayland-? | head -1)"); export HYPRLAND_INSTANCE_SIGNATURE=$(ls -t $XDG_RUNTIME_DIR/hypr | head -1); export DBUS_SESSION_BUS_ADDRESS=unix:path=$XDG_RUNTIME_DIR/bus;'

fail() {
    echo "$*" >&2
    exit 1
}
win() {
    ssh "${WIN_SSH[@]}" "$WIN_HOST" "$@"
}
# a file of build/omarchy-vm to the VM's folder on the Windows machine
put() {
    scp -q "${WIN_SSH[@]}" "$STATE/$1" "$WIN_HOST:${VM_DIR_FWD}/$1"
}
vmrun() {
    win "\"${VMWARE}\\vmrun.exe\" -T ws $*"
}
# a VM started over SSH dies with the session (OpenSSH on Windows ends what a session started), so it starts from a
# scheduled task, as scripts/win-run.sh starts the app; then waits for the guest's SSH, up to $1 times 10 seconds
vm_start() {
    printf '%s\r\n' "\"${VMWARE}\\vmrun.exe\" -T ws start \"${VMX}\" nogui" >"$STATE/start.cmd"
    put start.cmd
    win "schtasks /create /tn OmarchyVM /tr ${VM_DIR}\\start.cmd /sc once /st 23:59 /it /f >nul && schtasks /run /tn OmarchyVM >nul"
    local started=no
    for _ in $(seq 1 30); do
        if vmrun list | grep -qi omarchy.vmx; then
            started=yes
            break
        fi
        sleep 2
    done
    [ "$started" = yes ] || fail "The VM did not start (vmware.log in ${VM_DIR})"
    wait_for_ssh "${1:-60}"
}

# the guest's address: the newest of VMware's DHCP leases for the VM's fixed MAC (the file is not in time order)
guest_ip() {
    win "type C:\\ProgramData\\VMware\\vmnetdhcp.leases" | tr -d '\r' | awk -v mac="$MAC" '
        /^lease / { ip = $2 }
        /starts/ { starts = $3 " " $4 }
        $0 ~ "hardware ethernet " mac { if (starts > best) { best = starts; found = ip } }
        END { print found }'
}
# a clean shutdown from inside (vmrun's soft stop needs VMware Tools, which Omarchy does not run), hard after 2 minutes
vm_stop() {
    guest_sudo systemctl poweroff >/dev/null 2>&1 || true
    for _ in $(seq 1 24); do
        vmrun list | grep -qi omarchy.vmx || return 0
        sleep 5
    done
    vmrun stop "$VMX" hard
}
# the guest's address, looked up once per run (wait_for_ssh looks again while the VM boots)
GUEST_IP=
guest_address() {
    [ -n "$GUEST_IP" ] || GUEST_IP=$(guest_ip)
    [ -n "$GUEST_IP" ] || fail "The VM has no address yet"
}
guest() {
    guest_address
    ssh "${GUEST_SSH[@]}" "$GUEST_USER@$GUEST_IP" "$@"
}
# a command as root, sudo given the password
guest_sudo() {
    guest "echo '$(cat "$STATE/password")' | sudo -S $*"
}
# scp to or from the guest, the guest's side written as :path
guest_scp() {
    guest_address
    scp -q "${GUEST_SSH[@]}" "${1/#:/$GUEST_USER@$GUEST_IP:}" "${2/#:/$GUEST_USER@$GUEST_IP:}"
}
wait_for_ssh() {
    for _ in $(seq 1 "${1:-120}"); do
        GUEST_IP=$(guest_ip)
        if [ -n "$GUEST_IP" ] && guest true 2>/dev/null; then
            return 0
        fi
        sleep 10
    done
    fail "The VM did not answer over SSH"
}

create() {
    [ -f "$KEY" ] || ssh-keygen -q -t ed25519 -N '' -C "omarchy-vm" -f "$KEY"
    [ -f "$STATE/password" ] || openssl rand -hex 12 >"$STATE/password"
    win "if not exist $VM_DIR mkdir $VM_DIR"

    # the ISO, checked against Omarchy's key
    if ! win "if exist ${VM_DIR}\\${ISO} (exit 0) else (exit 1)"; then
        win "curl.exe -sSfL -o ${VM_DIR}\\${ISO}.sig https://iso.omarchy.org/${ISO}.sig && curl.exe -sSfL -o ${VM_DIR}\\${ISO} https://iso.omarchy.org/${ISO}"
    fi
    curl -sSf "https://keys.openpgp.org/vks/v1/by-fingerprint/${OMARCHY_KEY}" -o "$STATE/omarchy-key.asc"
    put omarchy-key.asc
    printf '%s\n' "cd ${VM_DIR_FWD}" 'export GNUPGHOME=$(mktemp -d)' 'gpg -q --import omarchy-key.asc' \
        "gpg --status-fd 1 --verify ${ISO}.sig ${ISO} 2>/dev/null | grep VALIDSIG" 'gpgconf --kill all' >"$STATE/verify.sh"
    put verify.sh
    win "\"C:\\Program Files\\Git\\bin\\bash.exe\" ${VM_DIR_FWD}/verify.sh" | grep -q "VALIDSIG ${OMARCHY_KEY} " ||
        fail "${ISO} is not signed with Omarchy's key"

    # the answers of the unattended install, as omarchy-iso's own integration test writes them
    local cidata="$STATE/cidata" hash disk_bytes=$((64 * 1024 * 1024 * 1024)) mib=$((1024 * 1024))
    local boot_start=$mib boot_size=$((2 * 1024 * 1024 * 1024))
    local main_start=$((boot_start + boot_size)) main_size
    main_size=$((disk_bytes - main_start - mib))
    hash=$(openssl passwd -6 "$(cat "$STATE/password")")
    rm -rf "$cidata"
    mkdir -p "$cidata"
    cp "$KEY.pub" "$cidata/authorized_keys"
    echo false >"$cidata/user_encrypt_installation.txt"
    cat >"$cidata/user_credentials.json" <<EOF
{ "root_enc_password": "$hash",
  "users": [ { "enc_password": "$hash", "groups": [], "sudo": true, "username": "$GUEST_USER" } ] }
EOF
    cat >"$cidata/user_configuration.json" <<EOF
{
    "app_config": null, "archinstall-language": "English", "auth_config": {},
    "audio_config": { "audio": "pipewire" },
    "bootloader_config": { "bootloader": "Limine", "uki": false, "removable": false },
    "custom_commands": [],
    "omarchy_install": {
        "mode": "full_disk", "defer_provisioning": false, "target_mount": "/mnt",
        "boot": { "esp_mount": "/boot", "esp_path": "/EFI/limine", "efi_binary": "limine_x64.efi", "enable_fallback": true },
        "storage": { "kernel": "linux-omarchy" }
    },
    "disk_config": {
        "config_type": "default_layout",
        "device_modifications": [ {
            "device": "/dev/nvme0n1", "wipe": true,
            "partitions": [
                { "btrfs": [], "dev_path": null, "flags": [ "boot", "esp" ], "fs_type": "fat32", "mount_options": [],
                  "mountpoint": "/boot", "obj_id": "ea21d3f2-82bb-49cc-ab5d-6f81ae94e18d",
                  "size": { "sector_size": { "unit": "B", "value": 512 }, "unit": "B", "value": $boot_size },
                  "start": { "sector_size": { "unit": "B", "value": 512 }, "unit": "B", "value": $boot_start },
                  "status": "create", "type": "primary" },
                { "btrfs": [ { "mountpoint": "/", "name": "@" }, { "mountpoint": "/home", "name": "@home" },
                             { "mountpoint": "/var/log", "name": "@log" }, { "mountpoint": "/var/cache/pacman/pkg", "name": "@pkg" } ],
                  "dev_path": null, "flags": [], "fs_type": "btrfs", "mount_options": [ "compress=zstd" ], "mountpoint": null,
                  "obj_id": "8c2c2b92-1070-455d-b76a-56263bab24aa",
                  "size": { "sector_size": { "unit": "B", "value": 512 }, "unit": "B", "value": $main_size },
                  "start": { "sector_size": { "unit": "B", "value": 512 }, "unit": "B", "value": $main_start },
                  "status": "create", "type": "primary" }
            ]
        } ]
    },
    "hostname": "omarchy-vm", "kernels": [ "linux-omarchy" ], "network_config": { "type": "iso" }, "ntp": true,
    "parallel_downloads": 8, "script": null, "services": [], "swap": true, "timezone": "UTC",
    "locale_config": { "kb_layout": "us", "sys_enc": "UTF-8", "sys_lang": "en_US.UTF-8" },
    "mirror_config": {
        "custom_repositories": [],
        "custom_servers": [ { "url": "https://mirror.omarchy.org/\$repo/os/\$arch" },
                            { "url": "https://geo.mirror.pkgbuild.com/\$repo/os/\$arch" } ],
        "mirror_regions": {}, "optional_repositories": []
    },
    "packages": [ "base-devel", "git", "omarchy-keyring", "omarchy-settings", "omarchy" ],
    "profile_config": { "gfx_driver": null, "greeter": null, "profile": {} },
    "version": "3.0.9"
}
EOF
    rm -f "$STATE/cidata.iso"
    hdiutil makehybrid -quiet -iso -joliet -default-volume-name cidata -o "$STATE/cidata.iso" "$cidata"
    put cidata.iso

    # the VM: UEFI without Secure Boot, PCIe root ports (vmxnet3 and NVMe need them), NVMe disk, both images on SATA, NAT with a fixed MAC, 3D on
    cat >"$STATE/omarchy.vmx" <<EOF
.encoding = "UTF-8"
config.version = "8"
virtualHW.version = "21"
displayName = "Omarchy"
guestOS = "other6xlinux-64"
firmware = "efi"
uefi.secureBoot.enabled = "FALSE"
memsize = "8192"
numvcpus = "6"
pciBridge0.present = "TRUE"
$(for n in 4 5 6 7; do printf 'pciBridge%s.present = "TRUE"\npciBridge%s.virtualDev = "pcieRootPort"\npciBridge%s.functions = "8"\n' $n $n $n; done)
nvme0.present = "TRUE"
nvme0:0.present = "TRUE"
nvme0:0.fileName = "omarchy.vmdk"
sata0.present = "TRUE"
sata0:0.present = "TRUE"
sata0:0.deviceType = "cdrom-image"
sata0:0.fileName = "${ISO}"
sata0:1.present = "TRUE"
sata0:1.deviceType = "cdrom-image"
sata0:1.fileName = "cidata.iso"
ethernet0.present = "TRUE"
ethernet0.connectionType = "nat"
ethernet0.virtualDev = "vmxnet3"
ethernet0.addressType = "static"
ethernet0.address = "${MAC}"
mks.enable3d = "TRUE"
svga.graphicsMemoryKB = "4194304"
usb.present = "TRUE"
usb_xhci.present = "TRUE"
sound.present = "FALSE"
tools.syncTime = "TRUE"
# the clock in UTC, as Linux reads it (VMware gives the host's local time otherwise, and the install's keys then
# come out hours "in the future" once NTP corrects it)
rtc.diffFromUTC = "0"
# a VNC console on the Windows machine's loopback, through an SSH tunnel: the screen in any state of the guest
RemoteDisplay.vnc.enabled = "TRUE"
RemoteDisplay.vnc.ip = "127.0.0.1"
RemoteDisplay.vnc.port = "5951"
EOF
    put omarchy.vmx
    win "if not exist ${VM_DIR}\\omarchy.vmdk \"${VMWARE}\\vmware-vdiskmanager.exe\" -c -s 64GB -a lsilogic -t 0 ${VM_DIR}\\omarchy.vmdk" >/dev/null
    echo "Installing (unattended, 10 to 20 minutes)"
    vm_start 180
    # SDDM logs the user in, so the desktop runs for the checks (Omarchy autologins only encrypted installs)
    guest_sudo "sh -c 'printf \"[Autologin]\nUser=$GUEST_USER\nSession=omarchy.desktop\n\" >/etc/sddm.conf.d/autologin.conf'" 2>/dev/null
    # VMware's SVGA3D runs Hyprland, but Quickshell (the bar, the notifications) gets no EGL surface on it, so Qt Quick
    # draws in software; and GTK 4's GL renderer loses its Wayland connection there, so GTK draws with cairo (these
    # checks then do not cover GTK's GL renderer). The desktop at 1920x1200, scale 1, in place of 1280x800 at scale 2:
    # Omarchy's own settings in monitors.lua, which its first boot writes
    guest 'mkdir -p ~/.config/uwsm && printf "%s\n" "# VMware SVGA3D: no EGL surface for Quickshell, Qt Quick draws in software" "export QT_QUICK_BACKEND=software" "# and GTK 4 GL loses its Wayland connection there (Nautilus as well): GTK draws with cairo" "export GSK_RENDERER=cairo" >>~/.config/uwsm/env'
    guest 'sed -i -e "s/^local omarchy_monitor_scale = .*/local omarchy_monitor_scale = 1/" -e "s/^local omarchy_gdk_scale = .*/local omarchy_gdk_scale = 1/" -e "s|^hl.monitor({ output = \"\", mode = \"preferred\"|hl.monitor({ output = \"\", mode = \"1920x1200@59.95\"|" ~/.config/hypr/monitors.lua'
    # the images out, or a reboot can start the ISO, which installs again from the cidata drive; the snapshot is
    # taken with the VM off (a snapshot of the running VM froze the guest)
    vm_stop
    printf '%s\r\n' "\$f = \"${VMX}\"" \
        '(Get-Content $f) -replace "^sata0:(0|1)\.present = .*", "sata0:`$1.present = `"FALSE`"" | Set-Content $f' >"$STATE/detach.ps1"
    put detach.ps1
    win "powershell -NoProfile -ExecutionPolicy Bypass -File ${VM_DIR}\\detach.ps1"
    vmrun snapshot "$VMX" clean
    vm_start
    echo "Omarchy ${OMARCHY_VERSION} is installed, snapshot 'clean'; scripts/omarchy-vm.sh ssh"
}

screenshot() {
    local out=${1:?the file of the screenshot}
    guest "$GUI grim /tmp/screen.png"
    guest_scp :/tmp/screen.png "$out"
    echo "$out"
}

# the screen from the VM's VNC console (vmx RemoteDisplay.vnc on the Windows machine's loopback) through an SSH
# tunnel, so also while it installs or when SSH does not answer; needs vncdo (pip install vncdotool)
console() {
    local out=${1:?the file of the screenshot}
    command -v vncdo >/dev/null || fail "No vncdo: pip install vncdotool"
    # its own connection: a forward through the shared one would outlive this call
    ssh -o ConnectTimeout=10 -o ControlPath=none -N -L 5951:127.0.0.1:5951 "$WIN_HOST" &
    local tunnel=$!
    sleep 2
    vncdo -s 127.0.0.1::5951 capture "$out" || true
    kill "$tunnel"
    [ -s "$out" ] || fail "No picture from the VNC console"
    echo "$out"
}

install_package() {
    local pkg=${1:?the package file}
    guest_scp "$pkg" ":/tmp/$(basename "$pkg")"
    # a fresh install has no sync databases (the dependencies come from Arch's repositories); a full upgrade first,
    # as pacman wants no partial ones, past Omarchy's hook that sends a direct upgrade to `omarchy update`
    guest_sudo "env OMARCHY_ALLOW_DIRECT_PACMAN=1 sh -c 'pacman -Syu --noconfirm && pacman -U --noconfirm /tmp/$(basename "$pkg")'" 2>/dev/null
}

case "${1:-}" in
create) create ;;
start) vm_start ;;
stop) vm_stop ;;
ip) guest_ip ;;
ssh)
    shift
    if [ $# -eq 0 ]; then guest; else guest "$GUI $*"; fi
    ;;
screenshot) screenshot "${2:-}" ;;
console) console "${2:-}" ;;
install) install_package "${2:-}" ;;
snapshot) vm_stop && vmrun snapshot "$VMX" "${2:?the snapshot name}" && vm_start ;;
revert)
    vmrun stop "$VMX" hard >/dev/null 2>&1 || true
    vmrun revertToSnapshot "$VMX" "${2:?the snapshot name}" && vm_start
    ;;
*)
    sed -n '2,18p' "$0"
    exit 2
    ;;
esac
