YELLOW="\e[33m"
GREEN="\e[0;32m"
NORMAL="\e[0m"
BGRED="\e[1;41m"

export PS1="${BGRED}${YELLOW}[initramfs]${NORMAL} ${GREEN}\h:\w${NORMAL} # "

alias vim=vi
alias reboot="/sbin/reboot -f"
alias poweroff="/sbin/poweroff -f"
alias wget="/bin/wget"

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
