#!/bin/busybox sh

VERSION="`cat /version`"
SERVER_URL="https://bootstrap.rnl.tecnico.ulisboa.pt"
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

info() {
    echo -e -n "\r${YELLOW} * ${1}${NORMAL}"
}

msg() {
    echo -e "${CYAN} * ${1}${NORMAL}"
}

error() {
    echo -e "  ${RED}${1}${NORMAL}"
}

function info() {
    echo -e "${CYAN}${1}${NORMAL}"
}

function warning() {
    echo -e "${RED}${1}${NORMAL}"
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

mac=`ip link show | awk '/([0-9A-Fa-f]{1,2}[:-]){5}([0-9A-Fa-f]{1,2})/{print $2}' | awk '!/^00:00/'`
echo "MAC: $mac"
echo

msg "Starting DHCP client"

while ! udhcpc -n  2>/dev/null | grep "\(Lease\|Adding\)" ; do
	msg "DHCP failed. Here's the output of 'ip link show'"
	ip link show
	msg "Press ENTER to retry"
	read
done

EXTRA_SUBNETS="193.136.154.128/26 193.136.154.0/25 10.16.82.0/24"
for subnet in $EXTRA_SUBNETS; do
	if ! ip route | grep "$subnet"; then
		msg "Adding extra route for ${subnet}"
		ip route add "${subnet}" dev eth0
	fi
done

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
	source "./do.sh"
	msg "script finished."
else
	error "Could not find do.sh"
fi

# don't want to drop to root shell when our servers are down...
for arg in $(cat /proc/cmdline); do
	if [ "$arg" = "--fallback-to-rescue-shell" ] ; then
		while :; do
			echo
			rescue_shell
		done
	fi
done

error "Will not drop to rescue shell (use --fallback-to-rescue-shell to enable)."
error "Press any key to reboot"
read
/bin/reboot
