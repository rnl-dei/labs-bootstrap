#!/bin/sh

header "RNL bootstrap script - Deploy image from torrent"

emerge parted
emerge mkfs.ext4
emerge transmission

info "Downloading torrent file"
/bin/wget --no-verbose "http://bootstrap.rnl.tecnico.ulisboa.pt/deploy.torrent" -P /torrents/

sleep 5
msg "Downloading complete script"
/bin/wget -O /completeScript.sh "http://bootstrap.rnl.tecnico.ulisboa.pt/completeScript.sh"

info "Starting Transmission"
transmission-daemon --logfile /transmission.log --config-dir /var/lib/transmission
