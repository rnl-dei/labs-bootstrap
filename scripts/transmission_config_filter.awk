#!/usr/bin/awk -f

# This scripts swaps values of specific settings in a json file
# Each setting must be on its own line

BEGIN {
	FS="\"" # Field Separator

	changes["download-dir"]   = "/downloads"
	changes["incomplete-dir"] = "/incomplete"
	changes["watch-dir"]      = "/torrents"
	changes["script-torrent-done-filename"] = "/completeScript.sh"
}

{
	var = $2

	if (var in changes)
		printf("\"%s\": \"%s\",\n", $2, changes[$2])
	else
		print
}
