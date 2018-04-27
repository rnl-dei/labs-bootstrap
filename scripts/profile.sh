#!/bin/sh

YELLOW="\e[33m"
GREEN="\e[0;32m"
NORMAL="\e[0m"
BGRED="\e[1;41m"

export PS1="${BGRED}${YELLOW}[initramfs]${NORMAL} ${GREEN}\h:\w${NORMAL} # "

alias vim=vi
alias wget="/bin/wget"

alias poweroff="/bin/poweroff"
alias shutdown="/bin/shutdown"
alias reboot="/bin/reboot"

install_and_run() {
	prog="$1"
	shift
	which "${prog}" >/dev/null
	if [ $? -ne 0 ]; then
		echo " ${prog} not yet installed, installing now..."
		emerge "${prog}"
	fi
	"${prog}" "$@"
}

# Dinamically set an alias for each package available
for cmd in $(emerge --list); do
	alias $cmd="install_and_run $cmd"
done
