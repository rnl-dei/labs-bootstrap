#!/usr/bin/awk -f

BEGIN {

	TRANSMISSION_CONFIG = "/root/rnlinux/roles/transmission/files/var/lib/transmission/.config/transmission/settings.json"

	changes["download-dir"]   = "/downloads"
	changes["incomplete-dir"] = "/incomplete"
	changes["watch-dir"]      = "/torrents"
	changes["script-torrent-done-filename"] = "/completeScript.sh"

	FS="\""

	while (getline < TRANSMISSION_CONFIG) {

		var = $2

		if (var in changes)
			printf("\"%s\": \"%s\",\n", $2, changes[$2])
		else
			print

	}
}
