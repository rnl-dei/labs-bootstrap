#!/bin/sh

SERVER_URL="https://geminio.rnl.tecnico.ulisboa.pt"

CYAN="\e[0;36m"
RED="\e[1;31m"
NORMAL="\e[0m"

info() {
    echo -e "${CYAN} * ${1}${NORMAL}"
}

warning() {
	echo -e $RED"$@"$NORMAL
}

pkg=${1}.tar.gz

info "Installing ${pkg}"
/bin/wget --no-verbose "${SERVER_URL}/packages/${pkg}"

if [ $? -eq 0 ]; then
	tar xzf "${pkg}" -C /
else
	warning "Package ${pkg} not found!"
fi
