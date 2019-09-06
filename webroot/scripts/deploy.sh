#!/bin/sh

header "RNL bootstrap script - Deploy image from torrent"

emerge parted
emerge mkfs.ext4
emerge transmission

info "Downloading torrent file"
/bin/wget --no-verbose "http://dolly.rnl.tecnico.ulisboa.pt/deploy.torrent" -P /torrents/

sleep 5

info "Starting Transmission"
transmission-daemon --logfile /transmission.log --config-dir /var/lib/transmission
