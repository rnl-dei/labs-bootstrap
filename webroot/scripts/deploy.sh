#!/bin/sh

header "RNL bootstrap script - Deploy image from torrent"

emerge parted
emerge mkfs.ext4
emerge transmission

info "Downloading torrent file"
/bin/wget --no-verbose "https://bootstrap.rnl.tecnico.ulisboa.pt/deploy.torrent" -P /torrents/

sleep 5
msg "Downloading complete script"
/bin/wget -O /completeScript.sh "https://bootstrap.rnl.tecnico.ulisboa.pt/completeScript.sh"

info "Starting Transmission"
transmission-daemon --logfile /transmission.log --config-dir /var/lib/transmission
