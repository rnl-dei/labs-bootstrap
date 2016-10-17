#!/bin/sh

YELLOW="\e[33m"
NORMAL="\e[0m"

warning() {
	echo -e "${YELLOW}${1}${NORMAL}"
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
				$1 != "'${parent_pid}'"	&&	\
				$2 != "{shutdown}"		\
				{print $1}' | xargs echo -n
}

shutdown_func() {
	action="$1"

	pids=$(pids_to_kill)

	if [ -z "$pids" ]; then
		warning "Nothing to terminate, ${action}ing..."
	else
		warning "Trying to gracefully termiante processes."
		echo "Sending SIGTERM to pids ${pids}"
		kill -TERM ${pids}

		count=10
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

if [ -z "$1" ]; then
	shutdown_func poweroff
else
	shutdown_func "$1"
fi
