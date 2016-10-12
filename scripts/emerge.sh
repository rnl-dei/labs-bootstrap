#!/bin/sh

SERVER_URL="https://geminio.rnl.tecnico.ulisboa.pt"

CYAN="\e[0;36m"
RED="\e[1;31m"
NORMAL="\e[0m"

info() {
	echo -e -n "\r${CYAN} * ${1}${NORMAL}"
}

warning() {
	echo -e $RED"$@"$NORMAL
}

pkg="${1}"
file="${pkg}.tar.gz"

info "${pkg} - Downloading...     "
wget_output=$(/bin/wget --no-verbose "${SERVER_URL}/packages/${file}" 2>&1)

if [ $? -ne 0 ]; then
	warning "Package '${pkg}' not found!"
	echo "$wget_output"
	exit
fi

info "${pkg} - Extracting...      "
tar xzf "${file}" -C /

info "${pkg} - Installation done\n"
