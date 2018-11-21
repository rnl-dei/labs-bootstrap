#!/bin/sh

header "Geminio bootstrap script - Surprise Edition"

emerge mpv

msg "Downloading video.mp4"
/bin/wget --no-verbose "http://geminio.rnl.tecnico.ulisboa.pt/files/video.mp4"

sleep 1
mpv -vo caca video.mp4

clear
msg "bye bye..."

sleep 1
/bin/reboot
