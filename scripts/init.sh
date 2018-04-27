#!/bin/busybox sh

VERSION="1.0.1"
SERVER_URL="https://geminio.rnl.tecnico.ulisboa.pt"
NTP_SERVER="ntp.rnl.tecnico.ulisboa.pt"

NORMAL="\e[0m"
CYAN="\e[0;36m"
RED="\e[1;31m"
GREEN="\e[32m"

rescue_shell() {
    rnl_header
    # "settsid cttyhack" -> Needed to have job control
    # "login" -> Use this instead of calling sh to source /etc/profile
    # "-f root" -> Needed to have login not ask authentication
    setsid cttyhack login -f root
}

msg() {
    echo -e "${CYAN} * ${1}${NORMAL}"
}

error() {
    echo -e "  ${RED}${1}${NORMAL}"
}

header() {
    echo -e "\n${GREEN}   ${1}${NORMAL}\n"
}

rnl_header() {
    header "RNL bootstrap initramfs ${VERSION} - $(uname -sr)"
}

trap "echo INT TERM" SIGINT SIGTERM
trap "echo USR1" USR1 USR2

# Create symlinks to all commands
/bin/busybox --install -s

# Mount /proc
mount -t proc none /proc

# Disable kernel spam to console
echo 1 > /proc/sys/kernel/printk

# Mount /sys and /dev
mount -t sysfs none /sys
mount -t devtmpfs none /dev

# Needed for ssh to function
mkdir /dev/pts
mount -t devpts devpts /dev/pts

# Load PT keymap
loadkmap < keymap.map

# Needed to connect to localhost
ip link set lo up

# Set TTL to distinguish between this initramfs and other OS
echo 32 > /proc/sys/net/ipv4/ip_default_ttl

rnl_header

msg "Starting DHCP client"
udhcpc 2>/dev/null | grep "\(Lease\|Adding\)"

if ip route | grep 193.136.154.0/25; then
	EXTRA_SUBNET="193.136.154.128/26"
else
	EXTRA_SUBNET="193.136.154.0/25"
fi

msg "Adding extra subnet route ${EXTRA_SUBNET}"
ip route add "${EXTRA_SUBNET}" dev eth0

msg "Starting SSH server"
/bin/sshd -E /sshd.log

msg "Starting NTP client"
ntpd -q -p "${NTP_SERVER}"

# Convert boot arguments to GET query syntax
args="$(cat /proc/cmdline | sed 's/ /\&/g')"

msg "Downloading script do.sh"
/bin/wget --no-verbose "${SERVER_URL}/do.sh?${args}" -O do.sh

if [ -f do.sh ]; then
	error "Executing script"
	source ./do.sh
else
	error "Could not find do.sh"
fi

while :; do
	echo
	rescue_shell
done
