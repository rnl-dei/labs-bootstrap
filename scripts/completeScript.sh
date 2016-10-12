#!/bin/sh
cd /downloads
script="$(find . -name run.sh)"

if [ -n "$script" ]; then
	script_dir=$(dirname ${script})
	cd "${script_dir}"
	chmod +x run.sh
	sh run.sh
else
	echo "Cannot find run.sh in /downloads"
fi
