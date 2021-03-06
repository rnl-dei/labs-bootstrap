#!/bin/sh

header "RNL bootstrap script - Surprise Edition"

# do not run forever!
# warning: be sure to test this in busybox before changing it
( sleep 2m; /bin/reboot ) & disown

emerge mpv

msg "Downloading video.mp4"
/bin/wget --no-verbose "https://bootstrap.rnl.tecnico.ulisboa.pt/files/video.mp4"


sleep 1
mpv -vo caca --no-input-default-bindings video.mp4 \
|| mpv -vo tct --no-input-default-bindings video.mp4

clear
msg "bye bye..."

sleep 1
/bin/reboot
# make sure we don't go to a rescue shell if reboot does not work
while sleep 2; do sleep 2;  done
