#!/bin/sh

YELLOW="\e[33m"
GREEN="\e[0;32m"
NORMAL="\e[0m"
BGRED="\e[1;41m"

export PS1="${BGRED}${YELLOW}[initramfs]${NORMAL} ${GREEN}\h:\w${NORMAL} # "

alias vim=vi
alias wget="/bin/wget"

#alias poweroff="shutdown poweroff" # doesn't work
alias poweroff='echo s > /proc/sysrq-trigger; sleep 2; echo u > /proc/sysrq-trigger; sleep 2; echo o > /proc/sysrq-trigger'

#alias reboot="shutdown reboot" # doesn't work
alias reboot='echo s > /proc/sysrq-trigger; sleep 2; echo u > /proc/sysrq-trigger; sleep 2; echo b > /proc/sysrq-trigger'


alias scp="install_and_run scp"
alias strace="install_and_run strace"
alias htop="install_and_run htop"

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
