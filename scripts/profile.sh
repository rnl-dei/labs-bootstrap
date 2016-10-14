#!/bin/sh

YELLOW="\e[33m"
GREEN="\e[0;32m"
NORMAL="\e[0m"
BGRED="\e[1;41m"

export PS1="${BGRED}${YELLOW}[initramfs]${NORMAL} ${GREEN}\h:\w${NORMAL} # "

alias vim=vi
alias wget="/bin/wget"

alias poweroff="shutdown poweroff"
alias reboot="shutdown reboot"

alias scp="install_and_run scp"
alias strace="install_and_run strace"
alias htop="install_and_run htop"

warning() {
	echo -e "${YELLOW}${1}${NORMAL}"
}

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

# Prints all pids except those associated with this function
# Yes, crude way to try to stop daemons, but effective
pids_to_kill() {
	own_pid=$$
	parent_pid=$(awk '/^PPid:/{print $2}' /proc/${own_pid}/status)
	ps_output=$(ps -o pid,args)
	echo "$ps_output" | awk 'NR > 1 &&			\
				$2 !~ /^\[/ &&			\
				$3 != "ps" &&			\
				$2 != "-sh" &&			\
				$1 != "1" &&			\
				$3 != "login" &&		\
				$1 != "'${own_pid}'" &&		\
				$1 != "'${parent_pid}'"		\
				{print $1}' | xargs echo -n
}

shutdown() {
	action="$1"

	pids=$(pids_to_kill)

	if [ -z "$pids" ]; then
		warning "Nothing to terminate, ${action}ing..."
	else
		warning "Trying to gracefully termiante processes."
		echo "Sending SIGTERM to pids ${pids}"
		kill -TERM ${pids}

		count=5
		while [ $((count--)) -gt 0 ]; do
			pids=$(pids_to_kill)
			[ -z "$pids" ] && break;
			echo "Waiting for some processes to terminate: $pids"
			sleep 1
		done

		if [ $count -lt 0 ]; then
			warning "I'm done waiting, ${action}ing anyway..."
		else
			warning "Everything terminated, ${action}ing..."
		fi
	fi

	/sbin/${action} -f
}
