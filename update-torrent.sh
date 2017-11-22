#!/bin/bash
## FIXME: This script is dirty and needs cleaning, sorry. - Jorge Heleno

function show_help() {
  printf "Usage: test torrent_file [-o|--output filename]\n"
  printf "                         [-h|--help] show help\n"
}

[[ $1 == "-h" || $1 == "--help" ]]  && show_help && exit
FILE=$1
OUTPUTDIR="/var/lib/transmission/Downloads"
TORRENTDIR="/var/lib/transmission/.config/transmission/torrents"


[[ -z $FILE ]] && show_help && exit
shift

function replace_torrent {

  echo "filename is $1"
  echo "output is $2"
  echo "torrent dir is $3"

  [[ -e "$2/$1" ]] && printf "File $2/$1 exists. Do you want to continue? [Ctrl-c to exit]\n" && read && rm -rf "$2/$1" && rm -f "/var/lib/transmission/torrents/${1}.torrent"

  

  transmission-create -p -o "${1}.torrent" -t udp://tracker.rnl.tecnico.ulisboa.pt:31000 $1
  cp -r $1 $2
  chown transmission:transmission $2/$1 -R
  chmod 777 "${1}.torrent"
  cp "${1}.torrent" "$3"
}

case "$1" in
  "-o" | "--output")
    if [[ -z $2 ]];then
      show_help
      exit
    fi
    OUTPUTDIR="$2"
    shift
    ;;
  "-h" | "--help")
    show_help
    exit
    ;;
  *)
    printf "Unrecognized option $1\n"
    show_help
    shift
    ;;
esac

if [[ -z $FILE ]];then
  show_help
  exit
fi

replace_torrent $FILE $OUTPUTDIR $TORRENTDIR


