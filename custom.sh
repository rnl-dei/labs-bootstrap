#!/bin/bash

# Define our custom files and variables to be used when generating the initramfs and packages

# Detect if this script is being sourced in another script or being run directly
[[ "${BASH_SOURCE[0]}" != "${0}" ]] && SOURCED=1

REPO=ansible_repo

get_root_pass() {
awk -f- ${REPO}/roles/users/vars/main.yml <<EOF
	BEGIN {
		FS="'"; # Field Separator
	}
	/name: 'root'/{
		user=1;
	}
	user && /password/ {
		print \$2;
		exit;
	}
EOF
}

get_cacert() {
	CA_URL="https://rnl.tecnico.ulisboa.pt/ca/cacert/cacert.pem"
	CA_CERT_DEST="/usr/local/share/ca-certificates/RNLcacert.crt"
	if ! test -e "$CA_CERT_DEST"; then
		if mkdir -p "$(dirname "$CA_CERT_DEST")" && wget "$CA_URL" -O "$CA_CERT_DEST"; then
			echo "Downloaded CA certificate."
		else
			echo "Could not download CA certificate!" >&2
			exit 1
		fi
	fi
	echo "$CA_CERT_DEST"
}

[[ ! "$SOURCED" ]] && CUSTOM_TARGET="$1"

if ! test -e $REPO; then
	echo "Could not find Linux ansible repo in '$REPO'! Please copy/link it."
	exit 1
fi

case "$CUSTOM_TARGET" in

	# This script is called with "transmission" from the Makefile to generate
	# the settings before creating the transmission package
	transmission)
		TR_SETTINGS="/dev/shm/settings.json"
		ansible all -i localhost, -c local -m template \
			-a "src=${REPO}/roles/transmission/templates/settings.json.j2 dest=$TR_SETTINGS" \
			--extra-vars=@${REPO}/roles/transmission/vars/main.yml
		;;

	# This script is sourced in the "create-initramfs" to have the following
	# variables defined and used to pass as arguments to the "mk-labs-bootstrap"
	*)
		SSHD_CONFIG="/dev/shm/sshd_config"

		ansible all -i localhost, -c local -m template \
			-a "src=${REPO}/roles/ssh/templates/sshd_config.j2 dest=${SSHD_CONFIG}" \
			--extra-vars=@${REPO}/roles/ssh/vars/main.yml

		SSH_HOST_KEYS="${REPO}/roles/ssh/files/etc/ssh"
		SSH_AUTHORIZED_KEYS="${REPO}/roles/ssh/files/root/.ssh/authorized_keys"
		CA_CERT="$(get_cacert)"
		ROOT_PASSWORD=$(get_root_pass)
		;;
esac
