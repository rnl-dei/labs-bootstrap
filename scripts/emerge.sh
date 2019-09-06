#!/bin/sh

SERVER_URL="http://dolly.rnl.tecnico.ulisboa.pt/packages"
DOWNLOAD_DIR="/root"

YELLOW="\e[33m"
RED="\e[1;31m"
NORMAL="\e[0m"

info() {
	echo -e -n "\r${YELLOW} * ${1}${NORMAL}"
}

warning() {
	echo -e $RED"$@"$NORMAL
}

pretty_list_packages() {
	echo -e "${YELLOW}Packages available on ${SERVER_URL}/:${NORMAL}"
	/bin/wget --quiet "${SERVER_URL}/" -O - | awk -F "\"" '/^<a href/{sub(".tar.gz", ""); print " - " $2}'
}

list_packages() {
	/bin/wget --quiet "${SERVER_URL}/" -O - | awk -F "\"" '/^<a href/{sub(".tar.gz", ""); print $2}'
}

pkg="${1}"
file="${pkg}.tar.gz"

if [ -z "${pkg}" -o "${pkg}" = "--help" ]; then
	echo "Usage: emerge <package name>"
	echo "Example: emerge htop"
	pretty_list_packages
	exit
fi

if [ "${pkg}" = "--list" ]; then
	list_packages
	exit
fi


info "${pkg} - Downloading...     "
wget_output=$(/bin/wget --no-verbose "${SERVER_URL}/${file}" -O "${DOWNLOAD_DIR}/${file}" 2>&1)

if [ $? -ne 0 ]; then
	warning "Package '${pkg}' not found!"
	rm "${DOWNLOAD_DIR}/${file}"
	echo "$wget_output"
	pretty_list_packages
	exit
fi

info "${pkg} - Extracting...      "
tar xzf "${DOWNLOAD_DIR}/${file}" -C /

info "${pkg} - Installation done\n"
