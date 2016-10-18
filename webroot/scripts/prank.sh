#!/bin/sh

header "Geminio bootstrap script - Surprise Edition"

emerge mpv

info "Downloading video.mp4"
/bin/wget --no-verbose "http://geminio.rnl.tecnico.ulisboa.pt/files/video.mp4"

sleep 1
mpv -vo caca video.mp4
#mpv -vo null video.mp4

rescue_shell

clear
info "bye bye..."
sleep 1
reboot -f
